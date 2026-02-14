@isTest
private class PaymentGatewayEventTriggerHandlerTest {
    
    // ======================
    // Global Mock for ERP Callouts
    // ======================
    private class MockERPCallout implements HttpCalloutMock {
        private String paymentId;
        
        public MockERPCallout(String paymentId) {
            this.paymentId = paymentId;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = '{"results":[{"status":"S","erpId":"ERP123","paymentid":"' + paymentId + '","receiptErpId":"RCP123","erpInvNumber":"INV123"}]}';
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
    
    // ======================
    // Test Setup
    // ======================
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account', 
                                  Email__c = 'test@example.com',
                                  PlaceOfRegistration__c = 'Abu Dhabi',
                                  RegistrationNumber__c = 'REG123',
                                  RegistrationExpiryDate__c = Date.today().addYears(1),
                                  UAEVATRegisterNumber__c = 'VAT123',
                                  ERPID__c = 'ncakjsuhf482'
                                 );
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'Test', LastName = 'User', Email = 'test@example.com', AccountId = acc.Id
        );
        insert con;
        
        Case testCase = new Case(
            Type = 'NOC',
            Status = 'New',
            Development_Name__c = 'Yas Island',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('District_Management').getRecordTypeId(),
            Subject = 'Test NOC Application',
            AccountId = acc.Id,
            Commencement_Date__c = Date.today(),
            Expiry_Date__c = Date.today().addYears(1),
            Number_Of_Installments__c =1,
            Request_split_payment__c = 'Yes',
            Total_Amount__c= 12000
            
            
        );
        insert testCase;
        
        Payment_Request__c paymentRequest = new Payment_Request__c(
            Case__c = testCase.Id,
            Status__c = 'Received',
            Amount__c = 100.00,
            Payment_Reference_No__c = 'REF123',
            Instalment_No__c = 1,
            Instalment_Percentage__c = 100,
            Instalment_Date__c = Date.today(),
            Transaction_No__c ='2384hfu49fnoseu2'
        );
        insert paymentRequest;
    }
    
    // ======================
    // Test Method
    // ======================
    @isTest
    static void testPaymentGatewayEvents() {
        List<Payment_Request__c> paymentRequests = [SELECT Id FROM Payment_Request__c LIMIT 1];
        System.assert(!paymentRequests.isEmpty(), 'Payment_Request__c must exist');
        // Payment_Request__c paymentRequest = paymentRequests[0];
        
        Payment_Request__c paymentRequest = [SELECT Id FROM Payment_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockERPCallout(paymentRequest.Id));
        Test.startTest();
        
        Payment_Gateway_Event__e paymentEvent = new Payment_Gateway_Event__e(
            Identifier__c = 'DM-Payment',
            Record_Id__c = paymentRequest.Id
        );
        
        Payment_Gateway_Event__e docGenEvent = new Payment_Gateway_Event__e(
            Identifier__c = 'DM-Payment-DOCGEN',
            Record_Id__c = paymentRequest.Id
        );
        Payment_Gateway_Event__e dmCaseEvent = new Payment_Gateway_Event__e(
            Identifier__c = 'DM-UpdateCase',
            Record_Id__c = paymentRequest.Id
        );
        EventBus.publish(new List<Payment_Gateway_Event__e>{paymentEvent, docGenEvent,dmCaseEvent});
        
        Test.stopTest();
    }
}