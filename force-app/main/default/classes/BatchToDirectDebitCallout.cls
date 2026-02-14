global class BatchToDirectDebitCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts{
    Set<Id> file_Ids_ForLog   = new Set<Id>();
    global void execute(SchedulableContext ctx) {
         database.executeBatch(new BatchToDirectDebitCallout(), 1);
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String unProcessedStatus = 'Unprocessed';
        String ADIBBankName = 'Abu Dhabi Islamic Bank'; 
        String query = 'SELECT DDBank__c,DirectDebitRequest__c,Id,Name,Requesttype__c,TransactionStatus__c FROM DDTransaction__c WHERE TransactionStatus__c =:unProcessedStatus AND APIEnabled__c = FALSE AND Is_EDDS__c = FALSE AND DDBank__c !=: ADIBBankName';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<DDTransaction__c> ddTransactionList){
        List<Id> ddTransactionIdList = new List<Id>();
       
        for(DDTransaction__c dDTransaction:ddTransactionList ){
            try{
                ddTransactionIdList.add(dDTransaction.Id);
            }catch(exception ex){
                file_Ids_ForLog.add(dDTransaction.id);
            } 
        }
        if(!ddTransactionIdList.isEmpty()){
            BatchToDirectDebitCalloutHelper.PrepareDataForCallout(ddTransactionIdList); 
        }
    }
    global void finish(Database.BatchableContext BC){
        if(file_Ids_ForLog.size()>0 || test.isRunningTest()){
            try{
                String htmlEmailBody = 'Following DD Transaction records could not be processed' + ' </br> ' ;
                htmlEmailBody += ' <b> ' + file_Ids_ForLog +' </b> ' ;
                String recipientString = Label.SysAdminEmailAddress;
                List<String> recipientList = recipientString.split(';');
                //recipientList.add('smanohar@aldar.com');
                Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'File Parsing Email Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            }catch(exception ex){
                system.debug(ex);
            }
        }
    }
    
    
}