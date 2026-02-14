@isTest
private class BrokerMarketingReimbursementControllTest {

    @isTest
    static void testControllerWithValidIdAndRenderVal() {
        // Create related Agency (assuming it's another custom object)
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Contact con = new Contact();
        con.Lastname='Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';  
        con.phone = '527583669';  
        con.MobilePhone = '527583669';
        insert con;
        
        con.FirstName = 'Test';
        con.LastName = 'User';
        update con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'ali.athamnehtest@pwc.com';
        insert agencyAdmin;
        
        // Create BrokerRequest with a relationship to Agency
        BrokerRequest__c request = new BrokerRequest__c(
            ApprovalStatus__c = 'Approved',
            InvoiceDate__c = Date.today(),
            InvoiceAmount__c = 1000,
            TaxAmount__c = 100,
            InvoiceStatus__c = 'Paid',
            AgencyName__c = accountRecord.Id
        );
        insert request;

        // Set page parameters
        Test.setCurrentPage(Page.BrokerMarketingReimbursementPDF); // Replace with actual VF page name
        ApexPages.currentPage().getParameters().put('brokerRequestId', request.Id);
        ApexPages.currentPage().getParameters().put('renderVal', 'pdf');

        // Run constructor
        Test.startTest();
        BrokerMarketingReimbursementController controller = new BrokerMarketingReimbursementController();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, controller.brokerRequest, 'Broker request should be populated');
        System.assertEquals(request.Id, controller.brokerRequest.Id, 'Broker request ID should match');
        System.assertEquals('pdf', controller.renderAsVal, 'Render value should be pdf');
    }

    @isTest
    static void testControllerWithNoId() {
        // Set empty parameters
        Test.setCurrentPage(Page.BrokerMarketingReimbursementPDF); // Replace with actual VF page name
        ApexPages.currentPage().getParameters().put('renderVal', 'pdf');

        // Run constructor
        Test.startTest();
        BrokerMarketingReimbursementController controller = new BrokerMarketingReimbursementController();
        Test.stopTest();

        // Assertions
        System.assertEquals(null, controller.brokerRequest.Id, 'Broker request should not have an ID');
    }
}