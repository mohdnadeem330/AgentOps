@isTest
private class DMcaseInvoiceControllerTest {
    @isTest
    static void DMcaseInvoiceController() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        Case testCase = new Case(
            Type = 'Permit To Work',
            Status = 'New',
            Subject = 'Test Permit To Work Application',
            Project_Name__c = 'Project Alpha',
            Request_Type__c = 'New',
            Development_Name__c='Yas Island',
            ContactId =con.Id,
            AccountId =acc.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;       
        Payment_Request__c testPaymentRequest = new Payment_Request__c(
            Amount__c = 1234.56,
            Status__c = 'Pending',
            Case__c = testCase.Id,
            Transaction_No__c = 'TR123',
            Transaction_Date__c = Date.today().addDays(-1),
            Payment_Date__c = Date.today(),
            Payment_Reference_No__c = 'REF123',
            Payment_Type__c = 'online'
        );
        
        insert testPaymentRequest;
        
        // Set up the page reference with the test Case ID
        PageReference pageRef = Page.DM_Invoice_pdf; // Replace YourPdfPageName with the actual name of your PDF generation page
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testPaymentRequest.Id);
        
        // Call the constructor of DMCasePdfHandler
        DMcaseInvoiceController handler = new DMcaseInvoiceController();
        
           }
}