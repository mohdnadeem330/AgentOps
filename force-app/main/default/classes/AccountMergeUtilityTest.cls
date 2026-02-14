@isTest
private class AccountMergeUtilityTest {

    private static testMethod void testAllMethods() {
        
        Account parent =TestObjectsFactory.getPersonAccountRecord(1234, 'United Arab Emirates', 'v123', 'p123');
        insert parent;

        Account child =TestObjectsFactory.getPersonAccountRecord(1235, 'United Arab Emirates', 'v123', 'p123');
        insert child;

        List<Account> allAccounts = AccountMergeUtility.queryInsertedAccounts(new List<Account>{parent,child});

        AccountMergeUtility.upsertAccounts(new List<Account>{child});
        AccountMergeUtility.findMaster(child);
        AccountMergeUtility.populateMasterFromChild(parent,child,true);
        AccountMergeUtility.mergeAccountsWithParents(new List<Account>{child});
    }

    private static testMethod void testFindPersonMaster() {
        
        Account parent =TestObjectsFactory.getPersonAccountRecord(123, 'United Arab Emirates', 'v123', 'p123');
        parent.FirstName = 'John';
        parent.PersonEmail = 'john@email.com';
        insert parent;

        Account child =TestObjectsFactory.getPersonAccountRecord(456, 'United States', 'v456', 'p456');
        insert child;
        child.FirstName = 'John';
        child.PersonEmail = 'john@email.com';
        child.ExistingAccount__c = parent.Id;

        list<Account> masterChild = AccountMergeUtility.findMaster(child);

        //System.assertEquals(2, masterChild.size(), 'Returned the wrong number of records.');
        //System.assertEquals(child.Id, masterChild[0].Id, 'Returned the wrong master record.');
        //System.assertEquals(parent.Id, masterChild[1].Id, 'Returned the wrong child record.');

    }

    private static testMethod void testFindMasterNone() {
        
        Account parent =TestObjectsFactory.getPersonAccountRecord(123, 'United Arab Emirates', 'v123', 'p123');
        parent.FirstName = 'John';
        parent.PersonEmail = 'john@email.com';
        insert parent;

        Account child =TestObjectsFactory.getPersonAccountRecord(456, 'United States', 'v456', 'p456');
        insert child;
        child.FirstName = 'John';
        child.PersonEmail = 'john1@email.com';
        child.ExistingAccount__c = parent.Id;

        list<Account> masterChild = AccountMergeUtility.findMaster(child);

        //System.assertEquals(null, masterChild, 'There should be no master');
    }

    private static testMethod void testFindCorporateDuplicate() {
        
        Account parent =TestObjectsFactory.getOrganisationAccountRecord('ABC LLC', '1234');
        parent.UniqueKey2__c = 'Test 2 keys';
        insert parent;

        Account child =TestObjectsFactory.getOrganisationAccountRecord('ABC LLC', '1234');
        parent.UniqueKey2__c = 'Test 2 keys';
        insert child;

        child = [Select Id,Name,ExistingAccount__c,ExistingAccount__r.Name,ExistingAccount__r.Id,IsPersonAccount From Account Where Id=:child.Id];
        AccountMergeUtility.findMaster(child);

        System.assertEquals(child.ExistingAccount__c, parent.Id, 'Existing Account is not populated correctly');
    }

    private static testMethod void testAccountCreationDuplicate() {
        
        Account parent =TestObjectsFactory.getPersonAccountRecord(123, 'United Arab Emirates', 'v123', 'p123');
        insert parent;

        Account child =TestObjectsFactory.getPersonAccountRecord(456, 'United States', 'v456', 'p456');
        insert child;

        List<Account> childAccounts = AccountMergeUtility.queryInsertedAccounts(new List<Account>{child});

        list<Account> masterChild =  AccountMergeUtility.upsertAccounts(new List<Account>{child});
        
    }

    private static testMethod void testFindCorporateNoDuplicate() {
        
        Account parent =TestObjectsFactory.getOrganisationAccountRecord('ABC LLC', '1234');
        insert parent;

        Account child =TestObjectsFactory.getOrganisationAccountRecord('ABC LLC New', '1234');
        insert child;

        child = [Select Id,Name,ExistingAccount__c,ExistingAccount__r.Name,ExistingAccount__r.Id From Account Where Id=:child.Id];
        list<Account> masterChild = AccountMergeUtility.findMaster(child);

    }

    

}