/**********************************************************************************************************************
* Name               : ReceiptRemittanceBatch                                                        
* Description        : Batch class to update receipt remittance status
* Usage              :                                                           
* Created By         : Muzammil Bajaria                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil Bajaria     08 Aug 2022       Initial Draft       
* 2.0           Muzammil Bajaria     03 Sept 2022      Calling integration batch from finish.      

******************************************************************************************************************/
global class ReceiptRemittanceBatch  implements Database.Batchable<sObject>, Database.Stateful,Schedulable, Database.AllowsCallouts {
    public List<ReceiptAcknowledgement__c> notMatchingReceipts; 
    public set<String> statusList = new Set<String>{'Received','Scanned Mismatch','Scanned'};
        List<Id> raIds  = new List<Id>();
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new ReceiptRemittanceBatch(), 100);
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        notMatchingReceipts = new List<ReceiptAcknowledgement__c>();
        String query = 'SELECT Id,Name,Status__c,RemittanceChequeDateText__c, Amount__c, RemittanceAmount__c, RemittanceChequeDate__c, RemittanceChequeNumber__c,ReferenceNumber__c,MaturityDate__c  FROM ReceiptAcknowledgement__c' ;
        query += ' WHERE Status__c IN:statusList AND RemittanceAmount__c != null AND RemittanceChequeNumber__c != null AND RemittanceChequeDateText__c != null ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ReceiptAcknowledgement__c> receiptList) {
        List<ReceiptAcknowledgement__c> receiptsToUpdate = new List<ReceiptAcknowledgement__c>();
        for(ReceiptAcknowledgement__c ra : receiptList){
            if(ra.RemittanceChequeDateText__c.contains('-')){
                String[] chequeDateList = ra.RemittanceChequeDateText__c.split('-');
                system.debug('chequeDateList '+chequeDateList);
                Date remittanceDate = date.newInstance(Integer.valueOf(chequeDateList[2]) ,Integer.valueOf(chequeDateList[1]),Integer.valueOf(chequeDateList[0]));
                system.debug('remittanceDate '+remittanceDate);
                ra.RemittanceChequeDate__c = remittanceDate;
                // && ra.MaturityDate__c == ra.RemittanceChequeDate__c 
                if(ra.RemittanceAmount__c == ra.Amount__c 
                   && ra.ReferenceNumber__c == ra.RemittanceChequeNumber__c
                  ){ // Removed cheque date condition.
                      ra.Status__c = 'Remitted';
                  }else{
                      ra.Status__c = 'Scanned Mismatch';
                      notMatchingReceipts.add(ra);
                  }
                raIds.add(ra.Id);
                receiptsToUpdate.add(ra);
            }
            
        }
       
        Database.SaveResult [] updateResult = database.update(receiptsToUpdate,false);
        for(Integer i=0;i<updateResult.size();i++){
            Database.SaveResult r = updateResult[i];
            if (!r.isSuccess()){
                for (Database.Error e : r.getErrors()){ 
                    LoggerService.Save( LoggerService.createApexLog(e, 'ReceiptRemittanceBatch - '+receiptsToUpdate[i].Id, 'ReceiptRemittanceBatch', 'execute'));
                    system.debug('e.getMessage() '+e.getMessage());  
                } 
            }
        }
        
        
    }
    
    global void finish(Database.BatchableContext BC) {
        system.debug('---raIds '+raIds);
        if (!raIds.isEmpty()) {
            // We are calling integration batch from finish because we cannot make callout same batch as we are performing DML.
            Database.executeBatch(new ReceiptIntegrationBatch(raIds), 50);
//            ReceiptCalloutHelper.PrepareDataForCallout(raIds);
            system.debug('---CALLED');
        }
    }
}