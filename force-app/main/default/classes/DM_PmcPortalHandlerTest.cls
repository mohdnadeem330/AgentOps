@isTest
public class DM_PmcPortalHandlerTest {

    @isTest
    static void testGetAllCases() {
        // Set up test data
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser100154325432X90@aldar.com'
        );
        insert testUser;

       Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;

        Test.startTest();
        System.runAs(testUser) {
            String result = DM_PmcPortalHandler.getAllCases(10, 1, '');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAllRequests() {
        // Set up test data
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser9879@test.com'
        );
        insert testUser;

       Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;

        Test.startTest();
        System.runAs(testUser) {
            List<Case> result = DM_PmcPortalHandler.getAllRequests();
            System.debug('Result: ' + result);
                    }
        Test.stopTest();
    }

    @isTest
    static void testGetDataToExport() {
        // Set up test data
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser76895@test.com'
        );
        insert testUser;

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;

        Test.startTest();
        System.runAs(testUser) {
            List<Case> result = DM_PmcPortalHandler.getDataToExport('');
            System.debug('Result: ' + result);
          
        }
        Test.stopTest();
    }

    @isTest
    static void testFetchDMCaseCount() {
        // Set up test data
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser86567@test.com'
        );
        insert testUser;

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Integer> result = DM_PmcPortalHandler.fetchDMCaseCount('Status');
            System.debug('Result: ' + result);
        }
        Test.stopTest();
    }
}