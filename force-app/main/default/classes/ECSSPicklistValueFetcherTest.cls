@isTest
public class ECSSPicklistValueFetcherTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            ECSS_Case_Types__c = 'Complaint;Maintenance;Inquiry'
        );
        insert testAccount;
    }

    @isTest
    static void testValidAccountWithPicklistValues() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<String> result = ECSSPicklistValueFetcher.pickListValues(testAccount.Id);
        Test.stopTest();

        System.assertEquals(3, result.size());
        System.assert(result.contains('Complaint'));
        System.assert(result.contains('Maintenance'));
        System.assert(result.contains('Inquiry'));
    }

    @isTest
    static void testValidAccountWithoutPicklistValues() {
        Account testAccount = new Account(
            Name = 'No Picklist Values',
            ECSS_Case_Types__c = null
        );
        insert testAccount;

        Test.startTest();
        List<String> result = ECSSPicklistValueFetcher.pickListValues(testAccount.Id);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @isTest
    static void testNullOrEmptyAccountId() {
        Test.startTest();
        List<String> resultWithNull = ECSSPicklistValueFetcher.pickListValues(null);
        List<String> resultWithEmpty = ECSSPicklistValueFetcher.pickListValues('');
        Test.stopTest();

        System.assertEquals(0, resultWithNull.size());
        System.assertEquals(0, resultWithEmpty.size());
    }

    
}