@isTest
public class DM_SendPaymentInvoiceTest {
    @isTest
    public static void testsendInvoicepdf() {
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Product2 testProduct = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert testProduct;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c='Yas Island',
            Status = 'New',
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c='Yes',
            ProductId=testProduct.id,
            Licensee_Email__c = 'test1@example.com'
        );
        insert testCase;
    
     	Payment_Request__c paymentRequest = new Payment_Request__c(Case__c = testCase.Id, Amount__c = 500,Status__c = 'Received',
                                                              Payment_Type__c = 'Wire Transfer' );
        insert paymentRequest;
        List<Payment_Request__c> paymentRequestList = New List<Payment_Request__c>();
        paymentRequestList.add(paymentRequest);
        DM_SendPaymentInvoice.sendInvoicepdf(paymentRequestList);
        Test.stopTest();
    }
    

}