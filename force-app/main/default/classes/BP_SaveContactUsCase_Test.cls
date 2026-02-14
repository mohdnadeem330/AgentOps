@isTest
private class BP_SaveContactUsCase_Test {
    @isTest
    static void testExecute_success() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // Do NOT assign to params. Just use as is (null or empty).
        // If your code requires params, handle null case or pass empty map.

        Map<String, Object> requestData = new Map<String, Object>{
            'phone' => '1234567890',
            'email' => 'test@example.com',
            'agentName' => 'John Doe',
            'agencyName' => 'Test Agency',
            'country' => 'India',
            'query' => 'Need help with a policy'
        };

        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestData));

        Test.startTest();
        BP_SaveContactUsCase.execute();
        Test.stopTest();
    }

    @isTest
    static void testExecute_missingFields() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Map<String, Object> requestData = new Map<String, Object>{
            'phone' => '',
            'email' => '',
            'agentName' => 'Test Agent',
            'agencyName' => '',
            'query' => ''
        };

        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestData));

        Test.startTest();
        BP_SaveContactUsCase.execute();
        Test.stopTest();

        System.debug('Handled missing fields gracefully.');
    }
}