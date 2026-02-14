@isTest(SeeAllData=false)
public class ValidateAgentWebServiceTest {
    @isTest static void setupMethod() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id); 

        Contact conRecord = [select id, AgentID__c	 from contact where id =: contactRecord.Id];
        
        System.debug('contactRecord '+contactRecord);
        Task task = TestObjectsFactory.getAgentActivity(conRecord.id);
        insert task;
        

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;

        Project__c projectRecord2 = TestObjectsFactory.getProjectRecord('25083');
        projectRecord2.Name = 'Mamsha Al Saadiyat';
        insert projectRecord2;

        Lead leadRec = TestObjectsFactory.getLeadRecord(1, 'Organization');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;

        Lead leadRecord1 = TestObjectsFactory.getLeadRecord(1, 'Organization');
        leadRecord1.Project__c = 'Mayan';
        leadRecord1.BrokerAgent__c = conRecord.id;
        leadRecord1.LeadSource = '800-Aldar' ;
        leadRecord1.EnquiryCategory__c = 'Kiosk' ;
        leadRecord1.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRecord1;

        Task leadTask = TestObjectsFactory.getLeadActivity(leadRec.id);        

        TestObjectsFactory.initializeRestContext(null, '/AgentDetails');
        ValidateAgentWebService.doPostMethod(conRecord.AgentID__c);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);

        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/AgentDetails');
        ValidateAgentWebService.doPostMethod('conRecor');
        Test.stopTest();

    }
}