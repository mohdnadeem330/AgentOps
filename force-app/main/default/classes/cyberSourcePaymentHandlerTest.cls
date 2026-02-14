@isTest
public class cyberSourcePaymentHandlerTest {
    
    @isTest
    static void callMethods() {
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Street',
            BillingCity = 'Abu Dhabi',
            BillingState = 'Abu Dhabi',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates',
            BillingCountryCode = 'AE'
        );
        insert testAccount;        
        Contact testcon = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id ,MobilePhone ='9666941790',Email = 'test@email.com');
        insert testcon;
        
        
        Case testCase = new Case(
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test TLA Application',
            AccountId = testAccount.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Development_Name__c='Yas Island'
            
        );
        insert testCase;
        string street = 'syntax';        
        Payment_Request__c testPaymentRequest = new Payment_Request__c(
            Case__c = testCase.Id,
            Amount__c = 100.50,
            Payment_Type__c = 'Online',
            Transaction_No__c = '123',
            Account__c = testAccount.Id,
            Reason_Code__c = '100'
        );
        insert testPaymentRequest;
        string paymentId;
        PageReference pageRef = Page.cyberSourcePaymentPage;
        Test.setCurrentPage(pageRef);
        String encryptedPaymentId = EncryptionUtils.encryptString(testPaymentRequest.Id);
        ApexPages.currentPage().getParameters().put('v','1234567890');
        ApexPages.currentPage().getParameters().put('id',encryptedPaymentId);
        CyberSourcePaymentHandler handler = new CyberSourcePaymentHandler();
        
        handler.initiatePayment();
        ApexPages.currentPage().getParameters().put('req_transaction_uuid', 'a4ZKH00000001QJ2AY');
        ApexPages.currentPage().getParameters().put('payer_authentication_transaction_id', '7157768524036599903005');
        ApexPages.currentPage().getParameters().put('auth_trans_ref_no', '7157768524036599903005');
        ApexPages.currentPage().getParameters().put('auth_amount', '1000');
        ApexPages.currentPage().getParameters().put('auth_reconciliation_reference_number', '413612177934');
        ApexPages.currentPage().getParameters().put('reason_code', '100');
        ApexPages.currentPage().getParameters().put('Transaction_Date__c', '12-3-2024');
        ApexPages.currentPage().getParameters().put('Transaction_No__c', '7157768524036599903005');
        ApexPages.currentPage().getParameters().put('auth_code', 'CC-831000');
        //handler.initiatePayment();
        handler.preparePaymentInfo();
        handler.getPaymentValidity();
        handler.getSignedData();
        handler.getParametersValues();
        
        
    }
}