@isTest
global class Dm_ERPIntegrationCtrlTest {
    public static String mockPaymentId;
    public static String mockResponseBody = null;
    public static Integer mockStatusCode = 200;
    
    @isTest
    static void erpTest() {
        Test.setMock(HttpCalloutMock.class, new DmERPHttpMock());
        
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        testAccount.ERPID__c = null;
        update testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Product2 testProduct = new Product2(
            Name = 'Road Closure Diversion',
            IsActive = true,
            Family = 'NOC'
        );
        insert testProduct;
        
        Id districtMgmtRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('District_Management').getRecordTypeId();
        
        /*
Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
if (rtMap.containsKey('District_Management')) {
districtMgmtRtId = rtMap.get('District_Management').getRecordTypeId();
}
*/
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            RecordTypeId = districtMgmtRtId,
            Type = 'NOC',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c = 'Yes',
            ProductId = testProduct.Id
        );
        insert testCase;
        
        Id districtMgmtRtIdTla = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('District_Management_TLA').getRecordTypeId();
        
        Case testCase2 = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            RecordTypeId = districtMgmtRtIdTla,
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c = 'Yes',
            ProductId = testProduct.Id
        );
        insert testCase2;
        
        Payment_Request__c paymentRequest1 = new Payment_Request__c(
            Case__c = testCase.Id,
            Amount__c = 500,
            Is_VAT_Applicable__c = true,
            Payment_Type__c = 'Online',
            Status__c = 'Received',
            ERP_Id__c = '4364812646846',
            ERP_Invoice_Number__c='732194732497234',
            Transaction_No__c = 'REF00143143',
            Cheque_Date__c = Date.today()
        );
        insert paymentRequest1;
        
        Payment_Request__c paymentRequest2 = new Payment_Request__c(
            Case__c = testCase2.Id,
            Amount__c = 900,
            Amount_without_VAT__c = 800,
            VAT_Amount__c = 100,
            Transaction_No__c ='123456765',
            Is_VAT_Applicable__c = true,
            Payment_Type__c = 'PDC',
            Status__c = 'Received',
            ERP_Id__c = '436481264446846',
            ERP_Invoice_Number__c='73219444732497234',
            Payment_Reference_No__c = 'REF002',
            Cheque_Date__c = Date.today()
        );
        insert paymentRequest2;
        
        mockPaymentId = paymentRequest2.Id;
        
        Test.startTest();
        Dm_ERPIntegrationCtrl.createPayments(paymentRequest1.Id, testCase.Id);
       Dm_ERPIntegrationCtrl.createPayments(paymentRequest2.Id, testCase2.Id);
        Dm_ERPIntegrationCtrl.createERPAccount(testCase.AccountId, new List<Logger__c>());
        Test.stopTest();
    }
    
    @isTest
    static void erpTestErrorPath() {
        // Simulate ERP error response to cover lines: 123, 167, 169, 177, 179, 191
        mockResponseBody = '{"results":[{"status":"E","paymentid":"' + mockPaymentId + '","errorMsg":"Invalid data"}]}';
        mockStatusCode = 200;
        
        Test.setMock(HttpCalloutMock.class, new DmERPHttpMock());
        
        // Reuse previously inserted case and payment data
       List<Case> existingCases = [SELECT Id FROM Case LIMIT 1];
List<Payment_Request__c> existingPRs = [SELECT Id, Case__c FROM Payment_Request__c LIMIT 1];
if (!existingCases.isEmpty() && !existingPRs.isEmpty()) {
    Test.startTest();
    Dm_ERPIntegrationCtrl.createPayments(existingPRs[0].Id, existingCases[0].Id);
    Test.stopTest();
}
        
        // Reset mock for future tests
        mockResponseBody = null;
        mockStatusCode = 200;
    }
    
    global class DmERPHttpMock implements HttpCalloutMock {
        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (Dm_ERPIntegrationCtrlTest.mockResponseBody != null) {
                res.setBody(Dm_ERPIntegrationCtrlTest.mockResponseBody);
                res.setStatusCode(Dm_ERPIntegrationCtrlTest.mockStatusCode);
            } else {
                res.setBody(
                    '{"results":[{"status":"S","paymentid":"' + Dm_ERPIntegrationCtrlTest.mockPaymentId + '","erpId":"ERP123","receiptErpId":"RCPT123"}]}'
                );
                res.setStatusCode(200);
            }
            return res;
        }
    }
}