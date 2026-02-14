public class DeleteOldLoggerRecordsBatch implements Database.Batchable<SObject>, Schedulable {
    
    public Integer numberOfDays;
    
    public DeleteOldLoggerRecordsBatch(Integer numDays) {
        this.numberOfDays = numDays;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        if (numberOfDays <= 90) {
            return Database.getQueryLocator([SELECT Id FROM Logger__c  WHERE Id = NULL]); 
        } else {
            Date thresholdDate = System.today().addDays(-numberOfDays);
            return Database.getQueryLocator([
                SELECT Id FROM Logger__c 
                WHERE CreatedDate < :thresholdDate
            ]);
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Logger__c> scope) {
        try {
            delete scope;
            System.debug('Deleted ' + scope.size() + ' Exception_Log__c records.');
        } catch (Exception e) {
            System.debug('Error deleting records: ' + e.getMessage());
            LoggerService.save(LoggerService.addApexLog(e,'DeleteOldLoggerRecordsBatch','execute',''));
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch job completed.');
    }
    
    public void execute(SchedulableContext SC) {
        Integer numDays =integer.valueof(label.DeleteOldLoggerDays);
        DeleteOldLoggerRecordsBatch batch = new DeleteOldLoggerRecordsBatch(numDays);
        Database.executeBatch(batch);
    }
}