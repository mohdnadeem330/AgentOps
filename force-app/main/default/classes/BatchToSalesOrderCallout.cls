global class BatchToSalesOrderCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    global void execute(SchedulableContext ctx) {
        Integer batchSize = Utilities.getConstantValue('SalesOrderAPIBatchSize');
        database.executeBatch(new BatchToSalesOrderCallout(), batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;

        Datetime whrClauseDate = Datetime.newInstance(2022, 08, 08);
        
        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.SALESORDER_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;

        String query = 'SELECT Id, Name, SyncStatus__c, RetryCount__c FROM SalesOrder__c WHERE (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCount__c <= :retryCount))';
        Constant__mdt constant = Utilities.getConstant('SalesOrderAPIErrorDate');
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
    
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> soList){
        List<Id> soIds = new List<Id>();
        for (SalesOrder__c so: soList) {
            soIds.add(so.Id);
        }
        System.debug('soIds>>>' + soIds);
        if (!soIds.isEmpty()) {
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}