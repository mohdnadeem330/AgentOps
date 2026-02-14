global class BatchToReceiptCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) {
        Integer batchSize = Utilities.getConstantValue('ReceiptAPIBatchSize');
        database.executeBatch(new BatchToReceiptCallout(), batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String inProgressSyncStatus = Constants.STATUS_IN_PROGRESS;
        String errorSyncStatus = Constants.STATUS_FAILED;

        Datetime whrClauseDate = Datetime.newInstance(2022, 08, 09);
        
        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(Constants.PAYMENT_CHQ_INTEGRATION);
        Decimal retryCount = mulesoftAPI.RetryCount__c;
        String CREDITNOTE = 'Credit Note';
        String query = 'SELECT Id, Name, SyncStatus__c, RetryCount__c, CreatedById, LastModifiedById FROM ReceiptAcknowledgement__c WHERE (SyncStatus__c = :inProgressSyncStatus OR (SyncStatus__c = :errorSyncStatus AND RetryCount__c <= :retryCount)) AND SalesOrder__r.ERPID__c != null AND PaymentType__c !=: CREDITNOTE AND SalesOrder__c != null';
        Constant__mdt constant = Utilities.getConstant('ReceiptAPIErrorDate');
        if (constant.ConstantValue__c != null) {
            List<String> dateSplit = constant.ConstantValue__c.split('-');
            Datetime startErrorDate = Datetime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), 00, 00, 00);
            Datetime endErrorDate = Datetime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), 23, 59, 59);
            query += ' AND (LastModifiedDate = TODAY OR (CreatedDate >=: startErrorDate AND CreatedDate <=: endErrorDate))';
        } else {
            query += ' AND LastModifiedDate = TODAY';
        }
        system.debug('query::'+query);
        system.debug('Database.getQueryLocator(query)::'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ReceiptAcknowledgement__c> raList){
        User nasirUser = Utilities.getUserDetailByEmail('nkhan@aldar.com');
        List<Id> raIds = new List<Id>();
        for (ReceiptAcknowledgement__c ra: raList) {
            if (ra.CreatedById != nasirUser.Id || ra.CreatedById != ra.LastModifiedById) {
                raIds.add(ra.Id);
            }
        }
        System.debug('raIds>>>' + raIds);
        if (!raIds.isEmpty()) {
            ReceiptCalloutHelper.PrepareDataForCallout(raIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}