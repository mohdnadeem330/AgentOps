global class BatchToMarketingReimbursementCallout  implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToMarketingReimbursementCallout(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String MarketingReimbursementRecordTypeId = Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID;
        String approvedStatus = Constants.APPROVED_STATUS;
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;

        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.MARKETING_REIMBURSEMENT_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;

        String query = 'SELECT Id, Name, RecordTypeId, ApprovalStatus__c, SyncStatus__c, RetryCount__c FROM BrokerRequest__c WHERE RecordTypeId = :MarketingReimbursementRecordTypeId AND ApprovalStatus__c = :approvedStatus AND (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCount__c <= :retryCount))';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<BrokerRequest__c> brList){
        List<Id> brIds = new List<Id>();
        for (BrokerRequest__c br: brList) {
            brIds.add(br.Id);
        }
        System.debug('brIds>>>' + brIds);
        if (!brIds.isEmpty()) {
            MarketingReimbursementCalloutHelper.PrepareDataForCallout(brIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}