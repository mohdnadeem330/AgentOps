@isTest
private class TestScheduledOutstandingAccountBatch {

    private class MockHttpCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"outStandingAmount": 100.0}');
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        // Create required Account with ERP ID
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c='12345';
        
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c newProject = new Project__c();
        newProject.Name = 'Haven';
        newProject.ProjectCode__c = 'Haven';
        newProject.CommunityName__c = 'Haven';
        newProject.CommunityNameArabic__c = 'المايا';
        newProject.BusinessUnitId__c = '749';
        //newProject.ProjectID__c = projectId;
        newProject.Country__c = 'United Arab Emirates';
        newProject.City__c = 'Dubai';
        newProject.CurrencyIsoCode = 'AED';
        newProject.StartDate__c = Date.today().addDays(-1);
        newProject.EndDate__c = Date.today().addMonths(5);
        newProject.ReservationAmount__c = 25000;
        newProject.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        Insert newProject;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(newProject.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(newProject.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'sold';
        unit.CompletionDate__c = System.today().addDays(7);
        insert unit;



        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'sold';
        salesOrder.Account__c = acc.Id;
        salesorder.Project_Name__c='Haven';
        insert salesOrder;

        // Insert API Metadata manually in org before test (cannot be inserted via test)
        // Insert OutstandingBalanceProjectEligibility__mdt with Project_Name__c = 'Haven' and Is_Active__c = true
    }

    @isTest
    static void testScheduledJobWhenEnabled() {
        // Enable custom setting
        BatchUpdateOutstandingAmountAccs__c setting = new BatchUpdateOutstandingAmountAccs__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_Outstanding_Balance_Check__c = true
        );
        insert setting;

        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());

        Test.startTest();
        String jobId = System.schedule(
            'Test Outstanding Balance Scheduler',
            '0 0 1 * * ?', // dummy CRON just for test
            new ScheduledOutstandingAccountBatch()
        );
        Test.stopTest();

        // Validate batch ran (optional)
        List<AsyncApexJob> jobs = [
    SELECT Id, JobType, Status, ExtendedStatus 
    FROM AsyncApexJob 
    WHERE Id = :jobId
];
        System.debug('jobs'+jobs);
//System.assertEquals(1, jobs.size(), 'Scheduled job should have started.');
//System.assertEquals('Completed', jobs[0].Status, 'Scheduled job should be completed.');

    }

    @isTest
    static void testScheduledJobWhenDisabled() {
        // Disable custom setting
        BatchUpdateOutstandingAmountAccs__c setting = new BatchUpdateOutstandingAmountAccs__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_Outstanding_Balance_Check__c = false
        );
        insert setting;

        Test.startTest();
        String jobId = System.schedule(
            'Test Outstanding Balance Scheduler Disabled',
            '0 0 1 * * ?',
            new ScheduledOutstandingAccountBatch()
        );
        Test.stopTest();

        // Since batch should not run, there should be no new AsyncApexJob of type BatchApex started by this scheduler
        // Optional check
    }
}