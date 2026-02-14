@isTest
public class ECSS_CustomerUpdateWebServiceTest {
    
    @testSetup
    static void setupData() {
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Id orgRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
 
        Account personAcc = new Account(
            RecordTypeId = personRT,
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = 'test@example.com',
            NationalIdNumber__pc = '7841987654321',
            PersonMobilePhone = '0501234567',
            MobilePhone__pc = '0501234567',
            MobileCountryCode__pc = '971'
        );
        insert personAcc;
 
        Account orgAcc = new Account(
            RecordTypeId = orgRT,
            Name = 'Test Org',
            Email__c = 'org@example.com',
            SapAccountID__c = 'ORG-SAP-EXIST'
        );
        insert orgAcc;
    }
 
    private static void setRestContext(String jsonBody) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/Ecss_ExistingCustomerUpdate';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;
    }
 
    @isTest
    static void test_SuccessfulUpdate() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'PersonEmail' => 'test@example.com',
            'Emirates_ID__c' => '7841987654321',
            'PersonMobilePhone' => '0501234567',
            'FirstName' => 'Test',
            'LastName' => 'User',
            'SapAccountID__c' => 'SAPID001',
            'RecordTypeId' => '1'
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_Update_OrgAccount() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'Email__c' => 'org@example.com',
            'RecordTypeId' => '2',
            'SapAccountID__c' => 'ORG-SAP-111'
        });
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_MissingFields_ShouldCreate() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'PersonEmail' => 'new@example.com',
            'Emirates_ID__c' => '7841234567890',
            'PersonMobilePhone' => '0509998888',
            'FirstName' => 'Auto',
            'LastName' => 'Create',
            'SapAccountID__c' => 'NEW-SAP-999',
            'RecordTypeId' => '1'
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_InvalidJson_Handling() {
        String invalidJson = '{ "UnknownKey":"SomeValue"}';
        setRestContext(invalidJson);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_EmptyBody_Handling() {
        setRestContext('{}');
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_CreateAccountMethod_AllFields() {
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Map<String, Object> reqMap = new Map<String, Object>{
            'FirstName' => 'New',
            'LastName' => 'User',
            'PersonEmail' => 'newuser@example.com',
            'PersonMobilePhone' => '0500000000',
            'RecordTypeId' => personRT,
            'SapAccountID__c' => 'NEW-SAP-100',
            'ECSS_Customer_Type__c' => 'Tenant',
            'CustomerVertical__c' => 'Aldar Estates',
            'MobileCountryCode__pc' => '971',
            'MobilePhone__pc' => '0500000000'
        };
        Test.startTest();
        Account acc = ECSS_CustomerUpdateWebService.createAccount(reqMap);
        Test.stopTest();
        System.assertNotEquals(null, acc.Id);
    }
 
    @isTest
    static void test_DuplicateSapHandling() {
        Account existing = [SELECT Id FROM Account WHERE PersonEmail = 'test@example.com' LIMIT 1];
        existing.SapAccountID__c = 'EXIST_SAP';
        update existing;
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

 
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'PersonEmail' => 'test@example.com',
            'Emirates_ID__c' => '7841987654321',
            'PersonMobilePhone' => '0501234567',
            'FirstName' => 'Test',
            'LastName' => 'User',
            'SapAccountID__c' => 'EXIST_SAP',
            'RecordTypeId' => personRT
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
@isTest
    static void test_orgAccSapHandling() {
        Account existing = [SELECT Id FROM Account WHERE Email__c = 'org@example.com' LIMIT 1];
        existing.SapAccountID__c = null;
        update existing;
        Id OrgRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();

 
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'Email__c' => 'test@example.com',
            'Emirates_ID__c' => '7841987654321',
            'PersonMobilePhone' => '0501234567',
            'Name' => 'Test',
            'SapAccountID__c' => 'EXIST_SAP',
            'RecordTypeId' => OrgRT
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_UnknownRecordTypeHandling() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'PersonEmail' => 'unknown@example.com',
            'FirstName' => 'Unknown',
            'LastName' => 'RT',
            'RecordTypeId' => '99'
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
 
    @isTest
    static void test_MultipleMatchingAccounts() {
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
 
        Account acc1 = new Account(
            RecordTypeId = personRT,
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = 'test@example.com',
            NationalIdNumber__pc = '7841111111111'
        );
        insert acc1;
 
        Account acc2 = new Account(
            RecordTypeId = personRT,
            FirstName = 'test',
            LastName = 'User2',
            PersonEmail = 'test@example.com',
            NationalIdNumber__pc = '7841111111111'
        );
        insert acc2;
 
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'PersonEmail' => 'test@example.com',
            'Emirates_ID__c' => '7841111111111',
            'PersonMobilePhone' => '0502223333',
            'FirstName' => 'test3',
            'LastName' => 'User',
            'SapAccountID__c' => 'MULTI-SAP-789',
            'RecordTypeId' => personRT
        });
 
        setRestContext(jsonBody);
        Test.startTest();
        ECSS_CustomerUpdateWebService.UpdateExistingCustomer();
        Test.stopTest();
    }
}