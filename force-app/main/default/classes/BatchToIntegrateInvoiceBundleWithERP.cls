global class BatchToIntegrateInvoiceBundleWithERP implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts, Schedulable{
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToIntegrateInvoiceBundleWithERP(), 1);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        String ApprovalStatus = 'Approved';
        String SyncStatus = 'Synced';
        List<String> InvoiceStatuses = new List<String>{'Pending Invoice Verification','Pending Finance Verification'};
        String query =  'SELECT AgencyAdmin__c,ApprovalStatus__c,ApprovedByBrokerHead__c,ApprovedByExeDirector__c,BrokerAgency__c,BrokerinvoiceBillToAddress1__c,BrokerinvoiceBillToAddress2__c,BrokerinvoiceBillToAddress3__c,BrokerinvoiceBillToName__c,BundleName__c,BundleNumber__c,Comments__c,CommentTrail__c,CreatedById,CreatedDate,DaysPassedTradyFoSubmission__c,ERPID__c,ErrorReason__c,Id,InitiatedDate__c,InvoiceDate__c,Name,OwnerId,PaidDate__c,SenttoFinanceDate__c,Status__c,SubmitforReview__c,SubmittedByAgencyDate__c,SyncStatus__c,TotalCommissionAmountWithVAT__c,TotalCommissionAmount__c,TotalCommissionLineItemCount__c,TotalNumberofCommission__c,TotalVATAmount__c,TRNNumber__c FROM InvoiceBundle__c WHERE ApprovalStatus__c =:ApprovalStatus AND SyncStatus__c !=: SyncStatus AND Status__c IN: InvoiceStatuses';
        system.debug('query::'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<InvoiceBundle__c> alliInvoiceBundleList){
        List<InvoiceBundleTriggerHandler.InputVariables> listInputVariables = new List<InvoiceBundleTriggerHandler.InputVariables>();
        InvoiceBundleTriggerHandler.InputVariables inClass = new  InvoiceBundleTriggerHandler.InputVariables();
        inClass.invoiceBundleList = alliInvoiceBundleList;
        listInputVariables.add(inClass);
        if(!listInputVariables.isEmpty()){
            InvoiceBundleTriggerHandler.prepareCallout(listInputVariables);
        }        
    }
    global void finish(Database.BatchableContext BC){ 
        
    }
}