@isTest
private class RunBatchProcessTest {
    
    @isTest
    static void testTriggerWithMergeCustomersBatchNew() {
        // Create test Accounts
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        orgAcc.ERPID__c = 'X170930922';
        insert orgAcc;
        
        // Comma-separated list of Account IDs
        String accountIds = orgAcc.Id;

        // Create the platform event
        StartBatchProcess__e event = new StartBatchProcess__e(
            BatchType__c = 'MergeCustomersBatchNew',
            RecordIds__c = accountIds
        );

        Test.startTest();
        // Publish the event
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest(); // This ensures trigger and batch execution
       
        System.assert(result.isSuccess(), 'Platform event publishing should succeed.');
    }

    @isTest
    static void testTriggerWithNonMatchingBatchType() {
        // Create event with irrelevant BatchType
        StartBatchProcess__e event = new StartBatchProcess__e(
            BatchType__c = 'SomeOtherBatch',
            RecordIds__c = '001000000000001'
        );

        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Platform event publishing should succeed.');
        // No batch should be executed, but we don't assert that here since batch monitoring requires mocks.
    }
}