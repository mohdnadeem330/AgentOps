@isTest
private class QuarterlyBonusWebserviceTest {
    @testSetup
    static void setupTestData() {
        QuarterlyBonusCommission__c qbc = new QuarterlyBonusCommission__c(
            Status__c = 'Ready for submission',
            ERPID__c = 'ERP123',
            Approval_Status__c = 'Approved',
            InvoiceDate__c = Date.today(),
            Quarter__c = 'Q1',
            Year__c = '2025',
            TotalCommissionAmount__c = 5000,
            TotalEligibleAmount__c = 4000
        );
        insert qbc;
    }
    
    @isTest
    static void testDoPostSuccess() {
        QuarterlyBonusCommission__c qbc = [SELECT Id FROM QuarterlyBonusCommission__c LIMIT 1];
        
        String requestBody = '{"qbcId":"' + qbc.Id + '","Status":"Invoice Approval In Progress", "ErpId":"ERP123", "invResponse":"Approved", "invApprName":"John Doe", "invApprComments":"Approved", "invApprDate":"2025-03-10"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        QuarterlyBonusWebservice.doPost();
        Test.stopTest();
        
        QuarterlyBonusCommission__c updatedQBC = [SELECT Status__c, InvoiceResponse__c FROM QuarterlyBonusCommission__c WHERE Id = :qbc.Id];
        System.assertEquals('Invoice Approval In Progress', updatedQBC.Status__c);
        System.assertEquals('Approved', updatedQBC.InvoiceResponse__c);
    }
    
    @isTest
    static void testDoPostWithPaymentApproval() {
        QuarterlyBonusCommission__c qbc = [SELECT Id FROM QuarterlyBonusCommission__c LIMIT 1];
        
        String requestBody = '{"qbcId":"' + qbc.Id + '","Status":"Payment Approval In Progress", "payResponse":"Approved", "payApprName":"Jane Doe", "payApprComments":"Approved", "payApprDate":"2025-03-11"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        QuarterlyBonusWebservice.doPost();
        Test.stopTest();
        
        QuarterlyBonusCommission__c updatedQBC = [SELECT Status__c, PaymentResponse__c FROM QuarterlyBonusCommission__c WHERE Id = :qbc.Id];
        System.assertEquals('Payment Approval In Progress', updatedQBC.Status__c);
        System.assertEquals('Approved', updatedQBC.PaymentResponse__c);
    }
    
    @isTest
    static void testDoPostWithBankClearance() {
        QuarterlyBonusCommission__c qbc = [SELECT Id FROM QuarterlyBonusCommission__c LIMIT 1];
        
        String requestBody = '{"qbcId":"' + qbc.Id + '","Status":"Payment Under Bank Clearance", "bankResponse":"Cleared", "bankComments":"Funds received", "bankApprDate":"2025-03-12"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        QuarterlyBonusWebservice.doPost();
        Test.stopTest();
        
        QuarterlyBonusCommission__c updatedQBC = [SELECT Status__c, BankResponse__c, BankComments__c, BankApprovedDate__c FROM QuarterlyBonusCommission__c WHERE Id = :qbc.Id];
        System.assertEquals('Payment Under Bank Clearance', updatedQBC.Status__c);
        System.assertEquals('Cleared', updatedQBC.BankResponse__c);
        System.assertEquals('Funds received', updatedQBC.BankComments__c);
        System.assertEquals(Date.valueOf('2025-03-12'), updatedQBC.BankApprovedDate__c);
    }
    
    @isTest
    static void testDoPostInvalidId() {
        String requestBody = '{"qbcId": null, "Status":"Invoice Approval In Progress"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        try {
            QuarterlyBonusWebservice.doPost();
           
        } catch (Exception e) {
            System.assertEquals('InvoiceBundleId cannot be null.', e.getMessage());
        }
        Test.stopTest();
    }
}