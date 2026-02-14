@isTest
public class CustomerCreateCaseServiceTest {
 
    static Id testAccountId;
    static Id testCaseId;
 
    @testSetup
    static void setupTestData() {
        Id personAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
 
        Account acc = new Account(
            LastName = 'Test User',
            PersonEmail = 'testuser@example.com',
            RecordTypeId = personAccountRT,
            PersonMobilePhone = '3333333333'
            );
        insert acc;
        testAccountId = acc.Id;
        Case cs = new Case(
            AccountId = acc.Id,
            Subject = 'Test Subject',
            SubVertical__c = 'Customer Management',
            Origin = 'Customer Portal',
            Status = 'New',
            RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT),
            Email_Not_Triggered__c = true,
            Assigned_To__c = UserInfo.getUserId()
        );
        insert cs;
        testCaseId = cs.Id;
    }
 
    private static void mockRestContext() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/customercreateCase';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
    }
 
    @isTest
    static void testWithDuplicateAccountFound() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'CreateCase',
            'Test User',
            'testuser@example.com',
            '9999999999',
            'Trigger duplicate logic',
            '',
            null,
            'a0U000000000111'
        );
        Test.stopTest();
    }
 
    @isTest
    static void testInsertNewAccount() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'CreateCase',
            'Unique User',
            'uniqueuser@example.com',
            '8888888888',
            'Insert account path',
            '',
            null,
            'a0U000000000222'
        );
        Test.stopTest();
    }
 
    @isTest
    static void testGetCaseOperation() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'GetCase',
            '',
            '',
            '',
            '',
            testAccountId,
            null,
            null
        );
        Test.stopTest();
    }
 
    @isTest
    static void testUpdateCaseOperation() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'UpdateCase',
            'Any User',
            'update@example.com',
            '1231231234',
            'Updated by test',
            null,
            testCaseId,
            null
        );
        Test.stopTest();
    }
 
    @isTest
    static void testMissingRequiredFields() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'CreateCase',
            '',
            '',
            '',
            'Missing required fields',
            null,
            null,
            null
        );
        Test.stopTest();
    }
 
    @isTest
    static void testCreateCaseWithQueue() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'CreateCase',
            'Queue User',
            'queueuser@example.com',
            '7777777777',
            'Queue path test',
            '', // New Account
            null,
            'a0U000000000333'
        );
        Test.stopTest();
    }
 
    @isTest
    static void testExceptionFlow() {
        mockRestContext();
        Test.startTest();
        CustomerCreateCaseService.doPost(
            'CreateCase',
            'Error User',
            'erroruser@example.com',
            '0000000000',
            'Simulated error',
            '001000000000000',
            null,
            'a0U000000000444'
        );
        Test.stopTest();
    }
}