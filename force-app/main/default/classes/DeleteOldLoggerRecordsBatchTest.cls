@isTest
public class DeleteOldLoggerRecordsBatchTest {
    
    @testSetup
    static void setupTestData() {
        List<Logger__c> loggers = new List<Logger__c>();
        
        for (Integer i = 0; i < 5; i++) {
            Logger__c logger = new Logger__c();
            logger.ExceptionLogId__c = '23/01/2025, 2:10 AM-CalloutToMuleSoft-calloutService- Line#-40';
            logger.ExceptionTypeName__c = 'DeserializationException';
            logger.ExceptionMessage__c = 'unknown protocol: https11';
            logger.StackTrace__c = 'text';
            logger.LogType__c = 'Service Exception';
            logger.Message__c = 'text';
            logger.ClassName__c = 'CalloutToMuleSoft';
            logger.ExecutingProcessName__c = 'customer';
            loggers.add(logger);
        }
        
        insert loggers;
        Test.setCreatedDate(loggers[0].Id, System.today().addDays(-180));

    }
    
    @isTest
    static void testStartMethodWithInvalidDays() {
        Test.startTest();
        DeleteOldLoggerRecordsBatch batch = new DeleteOldLoggerRecordsBatch(90);
        Database.QueryLocator queryLocator = batch.start(null);
        Test.stopTest();
    }
    
    @isTest
    static void testStartMethodWithValidDays() {
        Test.startTest();
        DeleteOldLoggerRecordsBatch batch = new DeleteOldLoggerRecordsBatch(120);
        Database.QueryLocator queryLocator = batch.start(null);
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        DeleteOldLoggerRecordsBatch batch = new DeleteOldLoggerRecordsBatch(120);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulableMethod() {
        Test.startTest();
        String cronExp = '0 0 0 15 3 ? 2035'; // This is just an example cron expression
        DeleteOldLoggerRecordsBatch schedulableBatch = new DeleteOldLoggerRecordsBatch(180);
        System.schedule('DeleteOldLoggerRecordsBatch Job', cronExp, schedulableBatch);
        Test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE CronExpression = :cronExp LIMIT 1];
        System.assertNotEquals(null, ct, 'The scheduled batch job should exist.');
    }
}