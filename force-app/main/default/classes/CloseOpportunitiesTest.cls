@isTest
private class CloseOpportunitiesTest {
    @isTest
    static void testBatchExecution() {
        // Create test data
        List<Opportunity> testOpportunities = new List<Opportunity>();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        for (Integer i = 0; i < 1; i++) { // Creating more than 200 to ensure batch splitting
            Opportunity newOppty = new Opportunity();
               
        newOppty.AccountId = acc.id ; 
        newOppty.CloseDate = system.today().adddays(10);
        newOppty.StageName = 'New';
        newOppty.ExpectedEndDate__c=System.Today();
        newOppty.EnquiryCategory__c = 'Aldar Employees';
        newOppty.EnquiryTrigger__c = 'Aldar';
        newOppty.SalesTypefromLead__c = 'Commercial Land';
        newOppty.PropertyUsage__c = 'Land';
        newOppty.Project__c = 'Al Falah';
        newOppty.LeadSource = 'Direct Call';
         
            testOpportunities.add(newOppty);
        }
        insert testOpportunities;
        Test.setCreatedDate(testOpportunities[0].Id, Date.today().addDays(-100) );  


        Test.startTest();

        // Schedule batch execution
        //String jobId = System.scheduleBatch(new CloseOpportunities(), 'CloseOpportunitiesBatchTest', 200);
        Id JObId = Database.executeBatch(new CloseOpportunities());
        system.debug('JObId'+JObId);
        Test.stopTest();

        // Verify batch job ID is not null
        System.assertNotEquals(null, jobId);

        // Verify the opportunities are updated
        List<Opportunity> updatedOpportunities = [SELECT Id, StageName, AutoCloseOpportunity__c, LossReason__c, LossComments__c FROM Opportunity];
        System.assertNotEquals(0, updatedOpportunities.size());
        for (Opportunity opp : updatedOpportunities)
        {
            System.assertEquals('Closed Lost', opp.StageName);
            System.assertEquals(true, opp.AutoCloseOpportunity__c);
            System.assertEquals('Lost - Future Potential', opp.LossReason__c);
            System.assertEquals('Auto Close after 45 Days', opp.LossComments__c);
        }
    }
}