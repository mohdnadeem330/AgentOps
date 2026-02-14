/**
     * Author: Upendra
     * Created Date: 2025-01-21
     */
@IsTest
private class BP_ValidateOTPTest {

  
    @IsTest
    static void testExecute_validRequest() {
        Contact con = new Contact();
        con.LastName = 'Test';
        con.Email = 'test@example.com';
        insert con;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/validateOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', con.Id);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_ValidateOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'), 'The response should indicate success');
        System.assertEquals('OTP Validated Successfully', response.get('message'), 'The success message should match');
    }

    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/validateOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); // Empty body

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_ValidateOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
    }

    @IsTest
    static void testExecute_withExceptionInCatchBlock() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/validateOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"malformedJson": '); // Malformed JSON

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_ValidateOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assert(response.get('message') != null, 'The error message should not be null');
    }

    @IsTest
    static void testExecute_withCatchBlockHandled() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/validateOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', 'InvalidContactId'); // Invalid contact ID
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_ValidateOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assert(response.get('message') != null);
    }

    @IsTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/validateOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = null;  // Null body to test failure
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            BP_ValidateOTP.excute();
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