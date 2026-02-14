global class BatchToCustomerCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) {
        Integer batchSize = Utilities.getConstantValue('CustomerAPIBatchSize');
        database.executeBatch(new BatchToCustomerCallout(), batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String organizationRecordTypeId = Constants.ORGANIZATION_RECORD_TYPE_ID;
        String personRecordTypeId = Constants.PERSON_RECORD_TYPE_ID;
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;

        Datetime whrClauseDate = Datetime.newInstance(2022, 08, 08);
        
        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.CUSTOMER_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;

        String query = 'SELECT Id, Name, RecordTypeId, SyncStatus__c, RetryCount__c, (SELECT Id FROM Opportunity_Units__r LIMIT 1) FROM Account WHERE (RecordTypeId = :organizationRecordTypeId OR RecordTypeId = :personRecordTypeId) AND (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCount__c <= :retryCount))';
        Constant__mdt constant = Utilities.getConstant('CustomerAPIErrorDate');
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
    
    global void execute(Database.BatchableContext BC, List<Account> accList){
        List<Id> accIds = new List<Id>();
        for (Account acc: accList) {
            Boolean isSalesOrderAvailable = false;
            for (SalesOrder__c salesOrder: acc.Opportunity_Units__r) {
                isSalesOrderAvailable = true;
                break;
            }
            if (isSalesOrderAvailable) {
                accIds.add(acc.Id);
            }
        }
        System.debug('accIds>>>' + accIds);
        if (!accIds.isEmpty()) {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, new List<Id>(), '');
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}