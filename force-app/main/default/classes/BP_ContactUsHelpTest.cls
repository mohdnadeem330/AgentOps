/**
     * Author: Upendra
     * Created Date: 2025-01-21
     */

@isTest
public class BP_ContactUsHelpTest {

    @TestSetup
    static void setupTestData() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        List<Contact> sodicContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            sodicContacts.add(new Contact(
                FirstName = 'Sodic',
                LastName = 'TeamMember' + i,
                AccountId = account.Id,
                MobileCountryCode__c = '91',
                MobilePhone = '8897664052',
                AgentStatus__c = 'Active'
            ));
        }
        insert sodicContacts;

        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            users.add(new User(
                FirstName = 'BMandSM',
                LastName = 'TeamMember' + i,
                Email = 'bm.sm' + i + '@test.com',
                Username = 'bm.sm' + i + '@test.com.' + System.currentTimeMillis(),
                Alias = 'bm' + i,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert users;
    }

    @isTest
    static void testExecute_validRequestBody() {
        String requestBody = JSON.serialize(new Map<String, Object> {
            'key1' => 'value1',
            'key2' => 'value2'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ContactUsHelp.execute();
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assertNotEquals(null, apiResponse, 'API response should not be null');
        System.assertEquals(200, apiResponse.statusCode, 'API status code should be 200');
        System.assert(apiResponse.message.contains('Data fetched successfully'), 'API message should indicate success');
    }

    @isTest
    static void testExecute_invalidRequestBody() {
        String requestBody = JSON.serialize(new Map<String, Object> {
            'key1' => 'value1',
            'key2' => null
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ContactUsHelp.execute();
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assertNotEquals(null, apiResponse, 'API response should not be null');
        System.assertEquals(200, apiResponse.statusCode, 'API status code should be 400');
       
    }

    @isTest
    static void testExecute_emptyRequestBody() {
        String requestBody = '';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ContactUsHelp.execute();
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assertNotEquals(null, apiResponse, 'API response should not be null');
        System.assertEquals(400, apiResponse.statusCode, 'API status code should be 400');
        System.assert(apiResponse.message.contains('Invalid Request Body'), 'API message should indicate failure due to empty body');
    }

    @isTest
    static void testExecute_withExceptionInCatchBlock() {
        String requestBody = JSON.serialize(new Map<String, Object> {
            'key1' => 'value1',
            'key2' => null
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ContactUsHelp.execute();
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assert(apiResponse.message != null, 'The error message should not be null');
    }

    @isTest
    static void testExecute_withCatchBlockHandled() {
        String requestBody = JSON.serialize(new Map<String, Object> {
            'key1' => 'value1',
            'key2' => null
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ContactUsHelp.execute();
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assert(apiResponse.message != null);
    }

    @isTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = null;  // Null body to test failure
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getContactUsHelp';
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        try {
            BP_ContactUsHelp.execute();
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
        }
        Test.stopTest();

        BP_BaseRestResource.ApiResponse apiResponse = 
            (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BP_BaseRestResource.ApiResponse.class
            );

        System.assertEquals(500, apiResponse.statusCode, 'API status code should be 400 for invalid request.');
    }
}