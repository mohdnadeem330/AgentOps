@isTest
public class dmPaymentSplitupHandlerTest {
    @isTest
    static void dmPaymentSplitup(){
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
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c='Yas Island',
            Status = 'New',
            Request_split_payment__c = 'Yes',
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c='Yes',
            ProductId=testProduct.id
        );
        insert testCase;
        
        dmPaymentSplitupHandler.getCaseInfo(testCase.Id);
        
        Payment_Request__c payment1 = new Payment_Request__c(Status__c ='Pending', Amount__c = -500);
        
        List<Payment_Request__c> payments = new List<Payment_Request__c>();
        payments.add(payment1);
        Test.startTest();
        try{
            dmPaymentSplitupHandler.createPaymentReqs(payments);
        }catch(exception e){
            System.debug('Exception caught: ' + e.getMessage());
        }       
        Test.stopTest();
    }
}