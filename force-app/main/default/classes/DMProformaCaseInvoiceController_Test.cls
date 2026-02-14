/**
* @File Name : DmProformaCaseInvoiceControllerTest.cls
* @Description : 
* @Author :Bhumika
* @Last Modified By : Bhumika 
* @Last Modified On : December 12, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 12, 2025 |   | Initial Version
**/

@isTest
private class DMProformaCaseInvoiceController_Test {
    @testSetup
    static void setupTestData() {
        // Create Account
      /*  Account acc = new Account(
            Name = 'Test Account',
            BillingCountry = 'United Arab Emirates',
            P_O_Box__c = '12345',
            Fax = '123456',
            MobileNumber1__c = '987654321',
            RegistrationNumber__c = 'REG123'
            //EmailAddress__c= 'test@123gmail.com'
        );
        insert acc;*/
		Id caserecordId = Schema.SObjectType.case.getRecordTypeInfosByName().get('District Management TLA').getRecordTypeId();

        // Create Case
        Case c = new Case(
           // AccountId = acc.Id,
            Origin = 'Phone',
            Status = 'New',
            Type = 'General',
            RecordTypeId = caserecordId
            
            //SuppliedEmail = 'test@123gmail.com'
        );
        insert c;
        // Insert Payment Requests
        List<Payment_Request__c> prList = new List<Payment_Request__c>();
        // 1st record → online
        prList.add(new Payment_Request__c(
            Case__c = c.Id,
            Amount__c = 105.0,
            Payment_Type__c = 'Online',
            Payment_Reference_No__c = 'REF-ONLINE'
        ));
        // 2nd record → Wire Transfer
        prList.add(new Payment_Request__c(
            Case__c = c.Id,
            Amount__c = 210.0,
            Payment_Type__c = 'Wire Transfer',
            Payment_Reference_No__c = 'REF-WIRE',
            Payment_Date__c = Date.today().addDays(-1)
        ));
        // 3rd record → Others
        prList.add(new Payment_Request__c(
            Case__c = c.Id,
            Amount__c = 315.0,
            Payment_Type__c = 'PDC',
            Payment_Reference_No__c = 'REF-CASH'
        ));
        insert prList;
    }
    @isTest
    static void testController() {
        // Fetch the Case ID
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        // Set Page Parameters
        PageReference pageRef = Page.DM_Proforma_Invoice;  // create a VF page named DummyPageForTest
        pageRef.getParameters().put('caseId', testCase.Id);
        pageRef.getParameters().put('transactionNo', 'TRN-123');
        Test.setCurrentPage(pageRef);
        // Run controller
        DMProformaCaseInvoiceController controller = new DMProformaCaseInvoiceController();
    }
}