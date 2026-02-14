/**
     * Author: Upendra
     * Created Date: 2025-01-21
     */

@IsTest
private class BP_LoggedInUserWebServiceTest {

    @IsTest
    static void testExecute_withValidRequest() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getLoggedInUserDetails';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('userId', testUser.Id);
            req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_LoggedInUserWebService.excute();
            Test.stopTest();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(true, response.get('success'), 'The response should indicate success');
        }
    }

    @IsTest
    static void testExecute_withEmptyRequestBody() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getLoggedInUserDetails';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = Blob.valueOf(''); 

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_LoggedInUserWebService.excute();
            Test.stopTest();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(false, response.get('success'), 'The response should indicate failure');
            System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
        }
    }

    @IsTest
    static void testExecute_withExceptionInCatchBlock() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getLoggedInUserDetails';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueOf('{"userId":'); 

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_LoggedInUserWebService.excute();
            Test.stopTest();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assert(response.get('message') != null, 'The error message should not be null');
        }
    }

    @IsTest
    static void testExecute_withCatchBlockHandled() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getLoggedInUserDetails';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('userId', 'InvalidUserId'); 
            req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_LoggedInUserWebService.excute();
            Test.stopTest();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assert(response.get('message') != null);
        }
    }

    @IsTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        System.runAs(createTestUser()) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getLoggedInUserDetails';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');

            req.requestBody = null; 
            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            try {
                BP_LoggedInUserWebService.excute();
            } catch (Exception e) {
                System.debug('Exception caught: ' + e.getMessage());
            }
            Test.stopTest();

            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            System.assertEquals(false, response.get('success'), 'Success should be false for invalid request.');
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
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert user;
        return user;
    }
}