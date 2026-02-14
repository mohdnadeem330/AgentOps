@isTest
private class DMCaseOVERSTAYPdfHandlerTest {
    @isTest
    static void testConstructor() {
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
        
        Case cs = new Case(
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c='Al Merief',
            Status = 'New',
            Subject = 'Test TLA Application',
            AccountId = testAccount.Id,
            Expiry_Date__c = Date.newInstance(2025, 8, 1),
            Commencement_Date__c = Date.newInstance(2024, 1, 1),
            HandOver_Date__c = Date.newInstance(2024, 8, 4),
            Annual_Fee_per_sqm__c = 1000,
            Penalty_Percentage__c = 5, 
            Temporary_Plot_Area__c = 500 
        );
        insert cs;
        
         Payment_Request__c testPaymentRequest = new Payment_Request__c(
            Amount__c = 1234.56,
            Status__c = 'Pending',
            Case__c = cs.Id,
            Transaction_No__c = 'TR123',
            Transaction_Date__c = Date.today().addDays(-1),
            Payment_Date__c = Date.today(),
            Payment_Reference_No__c = 'REF123',
            Payment_Type__c = 'online'
        );
        
        insert testPaymentRequest;
        
        Test.StartTest(); 
        PageReference pageRef = Page.DM_OverStay;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', cs.Id);      
        DMCaseOVERSTAYPdfHandler handler = new DMCaseOVERSTAYPdfHandler();
        Test.StopTest(); 
    }  
}