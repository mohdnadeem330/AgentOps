@IsTest
public class BrokerRemoveSuspensionBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Broker Agency ' + i,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId(),
                AgencyStatus__c = 'Suspended',
                SuspensionEndDate__c = Date.today().addDays(-1)
            );
            accounts.add(acc);
        }
        insert accounts;
    }
    
    @IsTest
    static void testBatchStart() {
        // Test the start method
        Test.startTest();
        BrokerRemoveSuspensionBatch batch = new BrokerRemoveSuspensionBatch();
        Database.QueryLocator queryLocator = batch.start(null);
        System.assertNotEquals(null, queryLocator);
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchExecute() {
        // Test the execute method
        Test.startTest();
        BrokerRemoveSuspensionBatch batch = new BrokerRemoveSuspensionBatch();
        List<Account> scope = [SELECT Id, AgencyStatus__c FROM Account WHERE AgencyStatus__c = 'Suspended'];
        batch.execute(null, scope);
        
        // Verify the updates
        List<Account> updatedAccounts = [SELECT Id, AgencyStatus__c, SuspensionRemovalReason__c FROM Account WHERE AgencyStatus__c = 'Active'];
        System.assertEquals(scope.size(), updatedAccounts.size());
        for (Account acc : updatedAccounts) {
            System.assertEquals('Active', acc.AgencyStatus__c);
            System.assertEquals('Removed Suspension from Backend via Scheduled Batch', acc.SuspensionRemovalReason__c);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchFinish() {
        // Test the finish method (though it's empty, we include it for coverage)
        Test.startTest();
        BrokerRemoveSuspensionBatch batch = new BrokerRemoveSuspensionBatch();
        batch.finish(null);
        Test.stopTest();
    }
    
    @IsTest
    static void testSchedulable() {
        // Test the Schedulable execute method
        Test.startTest();
        String chron = '0 0 23 * * ?';        
        String jobId = System.schedule('Test Schedule', chron, new BrokerRemoveSuspensionBatch());
        System.assertNotEquals(null, jobId);
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchExecutionInRealScenario() {
        // Test the complete execution of the batch class
        Test.startTest();
        Database.executeBatch(new BrokerRemoveSuspensionBatch());
        Test.stopTest();

        // Verify the updates
        // List<Account> updatedAccounts = [SELECT Id, AgencyStatus__c, SuspensionRemovalReason__c FROM Account WHERE AgencyStatus__c = 'Active'];
        // System.assertEquals(10, updatedAccounts.size());
        // for (Account acc : updatedAccounts) {
        //     System.assertEquals('Active', acc.AgencyStatus__c);
        //     System.assertEquals('Removed Suspension from Backend via Scheduled Batch', acc.SuspensionRemovalReason__c);
        // }
    }
}