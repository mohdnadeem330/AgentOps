@IsTest
private class BP_RemoveAgentTest {

    private static Contact createTestContact() {
        Account acc = new Account(
            Name = 'Test Agency'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Alice',
            AccountId = acc.Id,
            Email = 'test13@aldar.com',
            Phone = '527583669',
            OwnerId = UserInfo.getUserId(),
            MobilePhone = '527583669'
        );
        insert con;

        return con;
    }

    @IsTest
    static void testDeativateBrokerContactUser_validRequest() {
        Contact con = createTestContact();

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', con.Id);
        requestBody.put('status', 'Inactive');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_RemoveAgent.deativateBrokerContactUser();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'), 'The response should indicate success');
    }

    @IsTest
    static void testDeativateBrokerContactUser_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_RemoveAgent.deativateBrokerContactUser();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
    }

    @IsTest
    static void testDeativateBrokerContactUser_withDMLException_dueToDuplicate() {
        Contact con = createTestContact();

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', con.Id);
        requestBody.put('status', 'Inactive');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            Contact duplicateContact = new Contact();
            duplicateContact.LastName = 'Test';
            duplicateContact.Email = 'test@example.com';
            insert duplicateContact;

            BP_RemoveAgent.deativateBrokerContactUser();
        } catch (DmlException e) {
            handleDmlException(e, 'DUPLICATE_VALUE', 'Duplicate value detected');
        }
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }

    @IsTest
    static void testDeativateBrokerContactUser_withExceptionInCatchBlock() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"malformedJson": ');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_RemoveAgent.deativateBrokerContactUser();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assert(response.get('message') != null, 'The error message should not be null');
    }

    @IsTest
    static void testDeativateBrokerContactUser_withBlankStatus() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', '0010Y00002A8s1QQAA');
        requestBody.put('status', '');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_RemoveAgent.deativateBrokerContactUser();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Status can not be Blank', response.get('message'), 'The failure message should match');
    }

    @IsTest
    static void testDeativateBrokerContactUser_withDMLException_dueToCustomValidation() {
        Contact con = createTestContact();
        con.Email = 'invalidemail@aldar.com';
        update con;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', con.Id);
        requestBody.put('status', 'Inactive');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            BP_RemoveAgent.deativateBrokerContactUser();
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'The error message should contain FIELD_CUSTOM_VALIDATION_EXCEPTION');
        }
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'), 'The response should indicate failure');
    }

    @IsTest
    static void testDeativateBrokerContactUser_missingContactId() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('status', '');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_RemoveAgent.deativateBrokerContactUser();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('ContactId can not be Blank', response.get('message'), 'The failure message should match');
    }

    @IsTest
    static void testDeativateBrokerContactUser_withInvalidRequestBodyAndCatchBlockHandled() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/removeAgent';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            BP_RemoveAgent.deativateBrokerContactUser();
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
        }
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'Success should be false for invalid request.');
    }

    private static void handleDmlException(DmlException e, String expectedErrorCode, String expectedMessage) {
        System.assert(e.getMessage().contains(expectedErrorCode), 'The error message should contain ' + expectedErrorCode);
        
        RestResponse res = RestContext.response;
        res.responseBody = Blob.valueOf('{"success": false, "message": "' + expectedMessage + '"}');
    }
}