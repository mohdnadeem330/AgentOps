/*
*  Purpose - For RTO Pending SO - Batch to update SO to RTO Pending Approve if 1st Installment Line in partially cleared  and Other chnarges have ben cleared (Security Deposit)
*/

global class ValidateRTOSalesOrderPaymentBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful {
    private set<String> contactsIds;
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,Unit__c from SalesOrder__c where Status__c= \''+Constants.SO_STATUS_RTO_PENDING +'\' order by lastModifiedDate';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SalesOrder__c> scope){
        map<id,SalesOrder__c> salesOrdersToProcess = new map<id,SalesOrder__c>(scope);
        list<SalesOrder__c> salesOrdersToUpdate = new list<SalesOrder__c>();
        set<Id> handoverUnitIds = new set<Id>();
        //ADM Map
        map<id,Boolean> relatedSecurityDeposiyCharges = new map<id,Boolean>();
        map<id,Boolean> relatedInstallmentLines = new map<id,Boolean>();
        for(SalesOrderOtherCharges__c tempRec:[select id,Amount__c, InvoicedAmount__c,SalesOrder__c from SalesOrderOtherCharges__c where SalesOrder__c in :salesOrdersToProcess.keySet() and TypeOfCharge__c =: Constants.OTHER_CHARGES_TYPE_SECURITY_DEPOSIT and OutstandingAmount__c <= 100]){
            relatedSecurityDeposiyCharges.put(tempRec.SalesOrder__c,TRUE);
        }
        system.debug(relatedSecurityDeposiyCharges);
        for(InstallmentLines__c tempRec: [select id,InstallmentAmount__c,InvoicedAmount__c,SalesOrder__c,InstallmentDate__c from InstallmentLines__c where SalesOrder__c  in :salesOrdersToProcess.keySet() and InstallmentNumber__c = 1 and OutstandingAmount__c > 0 and InvoicedAmount__c > 0]){            
            relatedInstallmentLines.put(tempRec.SalesOrder__c,TRUE);
        }
        system.debug(relatedInstallmentLines);
        for(Id salesOrderId : salesOrdersToProcess.keySet()){
            Decimal diffValue=0;
            if( (relatedSecurityDeposiyCharges.containsKey(salesOrderId) && relatedSecurityDeposiyCharges.get(salesOrderId) == TRUE) || (relatedSecurityDeposiyCharges.containsKey(salesOrderId) && relatedSecurityDeposiyCharges.get(salesOrderId) == TRUE ) ){
                salesOrdersToUpdate.add(new SalesOrder__c(ID=salesOrderId,Status__c=Constants.SO_STATUS_RTO_Approve_PENDING ));
                handoverUnitIds.add(salesOrdersToProcess.get(salesOrderId).Unit__c);
            }
                
        }
        system.debug(salesOrdersToUpdate);
        if(!salesOrdersToUpdate.isEmpty()){
            update salesOrdersToUpdate;
            //Handover SR if not present
           // HandoverUtility.createHandoverSRUpdateSO(new list<ID>(handoverUnitIds));
        }
    }    
    global void finish(Database.BatchableContext bc){} 
}