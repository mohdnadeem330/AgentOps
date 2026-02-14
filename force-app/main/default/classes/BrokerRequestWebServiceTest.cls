@isTest
private class BrokerRequestWebServiceTest {
    @testSetup
    static void setupTestData() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        insert acc;
        
        // Create a test BrokerRequest__c record
        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;
    }
    
    @isTest
    static void testDoPost_InvApproverSuccess() {
        // Retrieve test data
        BrokerRequest__c brokerRequest = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        
        // Create request body
        String requestBody = '{"BrokerRequestId": "' + brokerRequest.Id + '", "invoiceStatus": "Invoice Approval In Progress", "invResponse" : "test","invApprName" : "sarfaraj", "invApprDate" : ""}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method
        Test.startTest();
        BrokerRequestWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_PayApproverSuccess() {
        // Retrieve test data
        BrokerRequest__c brokerRequest = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        
        // Create request body
        String requestBody = '{"BrokerRequestId": "' + brokerRequest.Id + '", "invoiceStatus": "Payment Approval In Progress"}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method
        Test.startTest();
        BrokerRequestWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_PaymentUnderApproverSuccess() {
        // Retrieve test data
        BrokerRequest__c brokerRequest = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        
        // Create request body
        String requestBody = '{"BrokerRequestId": "' + brokerRequest.Id + '", "invoiceStatus": "Payment Under Bank Clearance"}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method
        Test.startTest();
        BrokerRequestWebService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testDoPost_NoBrokerRequestId() {
        // Create invalid request body
        String requestBody = '{"invoiceStatus": "Sent to Finance"}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method and expect an exception
        try {
            Test.startTest();
            BrokerRequestWebService.doPost();
            Test.stopTest();
            //System.assert(false, 'Exception was expected but not thrown');
        } catch (Exception e) {
            System.assertEquals('BrokerRequestId cannot be null.', e.getMessage());
        }
    }
    
    @isTest
    static void testDoPost_InvalidBrokerRequestId() {
        // Create request body with a non-existent BrokerRequestId
        String requestBody = '{"BrokerRequestId": "fakeId123", "invoiceStatus": "Sent to Finance"}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method and expect an exception
        try {
            Test.startTest();
            BrokerRequestWebService.doPost();
            Test.stopTest();
            //System.assert(false, 'Exception was expected but not thrown');
        } catch (Exception e) {
            System.assertEquals('No Broker Request found with this BrokerRequestId.', e.getMessage());
        }
    }
    
    @isTest
    static void testDoPost_NullStatus() {
        // Retrieve test data
        BrokerRequest__c brokerRequest = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        
        // Create request body
        String requestBody = '{"BrokerRequestId": "' + brokerRequest.Id + '", "invoiceStatus": ""}';
        
        // Set mock request context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the method
        Test.startTest();
        BrokerRequestWebService.doPost();
        Test.stopTest();
        
        // Verify the update
        BrokerRequest__c updatedBrokerRequest = [SELECT InvoiceStatus__c FROM BrokerRequest__c WHERE Id = :brokerRequest.Id];
        //System.assertEquals('Sent to Finance', updatedBrokerRequest.InvoiceStatus__c);
    }
}