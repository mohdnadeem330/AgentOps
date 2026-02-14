global class BatchToAccountCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) {
        //adding for batch size 
        Integer batchSize = Utilities.getConstantValue('CustomerAPIBatchSize');
        database.executeBatch(new BatchToAccountCallout(), batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String brokerRecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;
        String pendingVerification = Constants.PENDING_VERIFICATION;

        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.AGENCY_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;

        String query = 'SELECT Id, Name, RecordTypeId, AgencyStatus__c, SyncStatus__c, RetryCount__c FROM Account WHERE RecordTypeId = :brokerRecordTypeId AND AgencyStatus__c !=: pendingVerification AND (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCount__c <= :retryCount))';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accList){
        List<Id> accIds = new List<Id>();
        for (Account acc: accList) {
            accIds.add(acc.Id);
        }
        System.debug('accIds>>>' + accIds);
        if (!accIds.isEmpty()) {
            AccountCalloutHelper.PrepareDataForCallout(accIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}