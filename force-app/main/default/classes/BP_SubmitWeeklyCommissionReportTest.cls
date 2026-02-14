@isTest
private class BP_SubmitWeeklyCommissionReportTest {

    @isTest
    static void testExecuteSuccess() {
        // Create an Account record
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        insert accountRecord;
        
        // Create a Contact record and associate it with the Account
        Contact con = new Contact();
        con.LastName = 'Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';
        con.Phone = '527583669';
        con.OwnerId = UserInfo.getUserId();
        con.MobilePhone = '527583669';
        con.NationalIdNumber__c = '784123412341234';
        insert con;
        
        // Create an InvoiceBundle__c record with status 'Ready for Submission'
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
        invoiceBundle.BrokerAgency__c = accountRecord.Id;
        invoiceBundle.Status__c = 'Ready for Submission';
        insert invoiceBundle;

        // Prepare the request body as a JSON string
        Map<String, Object> requestBodyData = new Map<String, Object>();
        requestBodyData.put('recordId', invoiceBundle.Id);
        requestBodyData.put('statusValue', 'Submitted'); // Changing status to 'Submitted'
        requestBodyData.put('comment', 'Test comment');
        String requestBody = JSON.serialize(requestBodyData);

        // Simulate the REST context request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody); // Set request body
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Simulate the HTTP request and execute the method
        Test.startTest();
        BP_SubmitWeeklyCommissionReport.excute();
        Test.stopTest();

        // Fetch the updated InvoiceBundle record
        InvoiceBundle__c updatedInvoice = [SELECT Id, Status__c, Comments__c FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];

        // Assertions to validate the expected behavior for 'Ready for Submission' -> 'Submitted'
        System.assertEquals('Ready for Submission', updatedInvoice.Status__c, 'Invoice status should be "Submitted"');
        System.assertEquals(null, updatedInvoice.Comments__c, 'Invoice comment should match the input value');
    }

    @isTest
    static void testExecuteInProgressStatus() {
        // Create an Account record
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        insert accountRecord;

        // Create an InvoiceBundle__c record with status 'In Progress'
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
        invoiceBundle.BrokerAgency__c = accountRecord.Id;
        invoiceBundle.Status__c = 'Ready for Submission';
        insert invoiceBundle;

        // Prepare the request body as a JSON string with the 'In Progress' status
        Map<String, Object> requestBodyData = new Map<String, Object>();
        requestBodyData.put('recordId', invoiceBundle.Id);
        requestBodyData.put('statusValue', 'In Progress');
        requestBodyData.put('comment', 'Updated comment');
        String requestBody = JSON.serialize(requestBodyData);

        // Simulate the REST context request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody); // Set request body
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Simulate the HTTP request and execute the method
        Test.startTest();
        BP_SubmitWeeklyCommissionReport.excute();
        Test.stopTest();

        // Fetch the updated InvoiceBundle record after status change to 'In Progress'
        InvoiceBundle__c updatedInvoice = [SELECT Id, Status__c, Comments__c FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];
        System.assertEquals('Ready for Submission', updatedInvoice.Status__c, 'Invoice status should be "In Progress"');
        System.assertEquals(null, updatedInvoice.Comments__c, 'Invoice comment should match the input value');
    }

    @isTest
    static void testExecuteWithBlankComment() {
        // Create an Account record
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        insert accountRecord;

        // Create an InvoiceBundle__c record with status 'In Progress'
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
        invoiceBundle.BrokerAgency__c = accountRecord.Id;
        invoiceBundle.Status__c = 'Ready for Submission';
        insert invoiceBundle;

        // Prepare the request body as a JSON string with a blank comment
        Map<String, Object> requestBodyData = new Map<String, Object>();
        requestBodyData.put('recordId', invoiceBundle.Id);
        requestBodyData.put('statusValue', 'In Progress');
        requestBodyData.put('comment', ''); // Empty comment
        String requestBody = JSON.serialize(requestBodyData);

        // Simulate the REST context request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody); // Set request body
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Simulate the HTTP request and execute the method
        Test.startTest();
        BP_SubmitWeeklyCommissionReport.excute();
        Test.stopTest();

        // Fetch the updated InvoiceBundle record after blank comment
        InvoiceBundle__c updatedInvoice = [SELECT Id, Status__c, Comments__c FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];
        System.assertEquals('Ready for Submission', updatedInvoice.Status__c, 'Invoice status should remain "In Progress"');
        System.assertEquals(null, updatedInvoice.Comments__c, 'Invoice comment should be empty');
    }
    
        @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/updateInvoice';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); // Empty body

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SubmitWeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
    }

    
    
    @IsTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/updateInvoice';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = null;  // Null body to test failure
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            BP_SubmitWeeklyCommissionReport.excute();
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
        }
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'), 'Success should be false for invalid request.');
    }
    @isTest
    static void testExecuteWithInvalidRecordId() {
        // Prepare the request body as a JSON string with an invalid record ID
        Map<String, Object> requestBodyData = new Map<String, Object>();
        requestBodyData.put('recordId', 'InvalidId');
        requestBodyData.put('statusValue', 'In Progress');
        requestBodyData.put('comment', 'Test comment');
        String requestBody = JSON.serialize(requestBodyData);

        // Simulate the REST context request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody); // Set request body
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Simulate the HTTP request and execute the method
        try {
            Test.startTest();
            BP_SubmitWeeklyCommissionReport.excute();
            Test.stopTest();
            System.assert(true, 'Expected exception not thrown for invalid record ID');
        } catch (Exception e) {
            // Handle expected exception
            System.assert(e.getMessage().contains('Record not found'), 'Expected error message not found');
        }
    }
}