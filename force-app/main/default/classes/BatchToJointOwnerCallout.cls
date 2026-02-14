global class BatchToJointOwnerCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    global void execute(SchedulableContext ctx) {
        Integer batchSize = Utilities.getConstantValue('JointOwnerAPIBatchSize');
        database.executeBatch(new BatchToJointOwnerCallout(), batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;

        Datetime whrClauseDate = Datetime.newInstance(2022, 08, 08);
        
        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.JOINTOWNER_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;

        String query = 'SELECT Id, Name, SyncStatus__c, RetryCounter__c FROM JointOwner__c WHERE (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCounter__c <= :retryCount) OR IsDeleted__c = true)';
        Constant__mdt constant = Utilities.getConstant('JointOwnerAPIErrorDate');
        if (constant.ConstantValue__c != null) {
            List<String> dateSplit = constant.ConstantValue__c.split('-');
            Datetime startErrorDate = Datetime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), 00, 00, 00);
            Datetime endErrorDate = Datetime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), 23, 59, 59);
            query += ' AND (LastModifiedDate = TODAY OR (CreatedDate >=: startErrorDate AND CreatedDate <=: endErrorDate))';
        } else {
            query += ' AND LastModifiedDate = TODAY';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<JointOwner__c> joList){
        List<Id> joIds = new List<Id>();
        for (JointOwner__c jo: joList) {
            joIds.add(jo.Id);
        }
        System.debug('joIds>>>' + joIds);
        if (!joIds.isEmpty()) {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}