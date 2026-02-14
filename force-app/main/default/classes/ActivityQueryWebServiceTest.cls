@isTest(SeeAllData=false)
public class ActivityQueryWebServiceTest {
    @isTest static void setupMethod() {        
       
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
                            
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
        Task leadTask = TestObjectsFactory.getLeadActivity(leadRec.Id);
        Task opportunityTask = TestObjectsFactory.getOpportunityActivity(opportunityRecord.Id);
        
        TestObjectsFactory.initializeRestContext(null, '/query/activity');
        ActivityQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        //insert leadTask;
        //insert opportunityTask;
        
        //TestObjectsFactory.initializeRestContext(null, '/query/activity');
        ActivityQueryWebService.doPost();
        
        Test.stopTest();
        
    }
}