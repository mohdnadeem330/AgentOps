/**
     * Author: Upendra
     * Created Date: 2025-01-21
     */

@IsTest
public class BP_GetAgentsDocTest {

    @IsTest
    static void testExecute_withValidRequest() {
        User testUser = createTestUser();
        Contact testContact = createTestContact();
        Document__c testDocument = createTestDocument(testContact.Id);

        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object> {
                'contactId' => testContact.Id,
                'role' => 'Partner/Owner'
            };
            req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

            RestContext.request = req;
            RestContext.response = new RestResponse();

            BP_GetAgentsDoc.excute();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(true, response.get('success'), 'Expected success to be true');
            System.assertEquals('Documents are fetched successfully', response.get('message'), 'Message does not match');
        }
    }

    @IsTest
    static void testExecute_withEmptyRequestBody() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = Blob.valueOf('');
            RestContext.request = req;
            RestContext.response = new RestResponse();

            BP_GetAgentsDoc.excute();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(false, response.get('success'), 'Expected success to be false');
            System.assertEquals('Invalid Request Body', response.get('message'), 'Message does not match');
        }
    }

    @IsTest
    static void testExecute_withException() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = Blob.valueOf('{"contactId":');
            RestContext.request = req;
            RestContext.response = new RestResponse();

            BP_GetAgentsDoc.excute();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(true, response.get('success'), 'Expected success to be true');
        }
    }

    @IsTest
    static void testExecute_withCatchBlockHandled() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = Blob.valueOf('{"contactId": "InvalidContactId"}');
            RestContext.request = req;
            RestContext.response = new RestResponse();

            BP_GetAgentsDoc.excute();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assert(response.get('message') != null, 'The error message should not be null');
        }
    }

    @IsTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = null;  // Null body to test failure
            RestContext.request = req;
            RestContext.response = new RestResponse();

            try {
                BP_GetAgentsDoc.excute();
            } catch (Exception e) {
                System.debug('Exception caught: ' + e.getMessage());
            }

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(false, response.get('success'), 'Success should be false for invalid request.');
        }
    }

    @IsTest
    static void testExecute_withValidRequestAnotherMethod() {
        User testUser = createTestUser();
        Contact testContact = createTestContact();
        Document__c testDocument = createTestDocument(testContact.Id);

        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getAgentsDoc';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object> {
                'contactId' => testContact.Id,
                'role' => 'Partner/Owner'
            };
            req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

            RestContext.request = req;
            RestContext.response = new RestResponse();

            BP_GetAgentsDoc.excute();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(true, response.get('success'), 'Expected success to be true');
            System.assertEquals('Documents are fetched successfully', response.get('message'), 'Message does not match');
        }
    }

    private static User createTestUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'test',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static Contact createTestContact() {
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        accountRecord.OwnerId = UserInfo.getUserId();
        insert accountRecord;

        Contact con = new Contact();
        con.LastName = 'Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';
        con.Phone = '527583669';
        con.OwnerId = UserInfo.getUserId();
        con.MobilePhone = '527583669';
        insert con;

        return con;
    }

    private static Document__c createTestDocument(Id contactId) {
        User agencyAdmin = [SELECT Id, Email, ContactId FROM User LIMIT 1];

        Id recordTypeID = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('BrokerDocuments').getRecordTypeId();

        Document__c documentRecord = DocumentService.createDocumentRecord('','','','Emirates ID Copy','','', recordTypeID);

        documentRecord.Contact__c = agencyAdmin.ContactId;
        documentRecord.SendForESign__c = false;
        documentRecord.DocumentPlaceHolderId__c = 'test';
        documentRecord.EligibleForeSign__c = true;

        insert documentRecord;

        return documentRecord;
    }
}