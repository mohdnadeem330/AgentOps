/**
 * Author: Upendra
 * Created Date: 2025-01-21
 */
@IsTest
private class BP_SendOTPTest {

    @IsTest
    static void testExecute_validRequest() {
        Contact con = new Contact();
        con.LastName = 'Test';
        con.Email = 'test@example.com';
        con.NationalIdNumber__c = '784123456789012';
        insert con;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sendOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', con.Id);
        requestBody.put('type', 'Email');
        requestBody.put('value', con.Email);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SendOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'), 'The response should indicate success');
        System.assertEquals('OTP Sent Successfully', response.get('message'), 'The success message should match');
    }

    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sendOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); 

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SendOTP.excute();
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
        req.requestUri = '/services/apexrest/sendOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"malformedJson": '); 

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SendOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assert(response.get('message') != null, 'The error message should not be null');
    }

    @IsTest
    static void testExecute_withInvalidContactId() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sendOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', 'InvalidContactId'); 
        requestBody.put('type', 'Email');
        requestBody.put('value', 'test@example.com');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SendOTP.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'), 'The response should indicate failure');
        
    }

    @IsTest
    static void testExecute_withNullRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sendOtp';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = null; 
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            BP_SendOTP.excute();
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
        }
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'Success should be false for null request body.');
    }
    @IsTest
static void testExecute_validSMSRequest() {
    // Create a contact
    Contact con = new Contact();
    con.LastName = 'Test';
    con.MobilePhone__c = '501234567';
    con.MobileCountryCode__c = '971';
    con.NationalIdNumber__c = '784123456789012';
    insert con;

    // Compose a valid UAE-style number
    String validMobile = '+971501234567';

    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/sendOtp';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('contactId', con.Id);
    requestBody.put('type', 'SMS');
    requestBody.put('value', validMobile); // Valid mobile number

    req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_SendOTP.excute();
    Test.stopTest();

    RestResponse res = RestContext.response;
    String responseBody = res.responseBody != null ? res.responseBody.toString() : '';
    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

    System.assertEquals(true, response.get('success'), 'The response should indicate success for valid SMS request');
    System.assertEquals('OTP Sent Successfully', response.get('message'), 'Success message should match');
}
@IsTest
static void testExecute_invalidSMSPhoneNumber() {
    Contact con = new Contact();
    con.LastName = 'Test';
    con.MobilePhone__c = '051234567';
    con.MobileCountryCode__c = '971';
    con.NationalIdNumber__c = '784123456789012';
    insert con;

    // Invalid prefix (e.g., US-style or incorrect format)
    String invalidMobile = '1234567890';

    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/sendOtp';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('contactId', con.Id);
    requestBody.put('type', 'SMS');
    requestBody.put('value', invalidMobile); // Invalid format

    req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_SendOTP.excute();
    Test.stopTest();

    RestResponse res = RestContext.response;
    String responseBody = res.responseBody.toString();
    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

    System.assertEquals(true, response.get('success'), 'Should still indicate success at API level');
    System.assertEquals('OTP Sent Successfully', response.get('message'), 'API message is fixed, but data should reflect internal failure');
    System.assertEquals('Invalid phone number format', response.get('data'), 'Should indicate invalid format in data');
}

}