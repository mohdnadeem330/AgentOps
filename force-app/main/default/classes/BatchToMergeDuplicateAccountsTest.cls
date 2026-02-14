@isTest
private class BatchToMergeDuplicateAccountsTest {
    

    private static testMethod void testAllMethods() {
        
        Account parent =TestObjectsFactory.getPersonAccountRecord(1234, 'United Arab Emirates', 'v123', 'p123');
        insert parent;

        Account child =TestObjectsFactory.getPersonAccountRecord(1235, 'United Arab Emirates', 'v123', 'p123');
        insert child;

        Test.startTest();
        BatchToMergeDuplicateAccounts mergeAccountBatch = new BatchToMergeDuplicateAccounts ();
        database.executeBatch(mergeAccountBatch,1);
        String timeSchedule ='0 0 23 * * ?'; 
        System.schedule('Merge Accounts', timeSchedule,mergeAccountBatch);
        Test.stopTest();
    }
}