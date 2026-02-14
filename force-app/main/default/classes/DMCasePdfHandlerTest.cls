@isTest
private class DMCasePdfHandlerTest {
    @isTest
    static void testPdfGeneration() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Case testCase = new Case(
            Type = 'Permit To Work',
            Status = 'New',
            Development_Name__c = 'Saadiyat Island',
            Subject = 'Test Permit To Work Application',
            Project_Name__c = 'Project Alpha',
            Request_Type__c = 'New',
            ContactId =con.Id,
            AccountId =acc.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()            
        );
        insert testCase; 
        Payment_Request__c testPaymentRequest = new Payment_Request__c(
            Amount__c = 1234.56,
            Status__c = 'Pending',
            Payment_Type__c = 'Online',
            Case__c = testCase.Id
        );
       
        insert testPaymentRequest;
        
        // Set up the page reference with the test Case ID
        PageReference pageRef = Page.DM_NOC_pdf; // Replace YourPdfPageName with the actual name of your PDF generation page
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testCase.Id);
        
        // Call the constructor of DMCasePdfHandler
        DMCasePdfHandler handler = new DMCasePdfHandler();
        
        // Assert that properties are populated as expected
        System.assertEquals(testCase.Id, handler.caseRecord.Id);
        // Add more assertions as needed
    }
}