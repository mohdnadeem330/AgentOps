@isTest(SeeAllData=false)
public class CreateAgentActivityWebserviceTest {
    @isTest static void setupMethod() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id); 

        Contact conRecord = [select id, AgentID__c	 from contact where id =: contactRecord.Id];

        TestObjectsFactory.initializeRestContext(null, '/CreateActivity');
        CreateAgentActivityWebservice.doPostMethod(conRecord.AgentID__c, 'L9383892', 'Roadshow', '', '', '');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        CreateAgentActivityWebservice.doPostMethod(conRecord.AgentID__c, 'L9383892', 'Mayan', '', '', '');
        
        TestObjectsFactory.initializeRestContext(null, '/CreateActivitysss');
        CreateAgentActivityWebservice.doPostMethod(conRecord.Id, 'L9383892', 'Mayan', '', '', '');
        
        Test.stopTest();
    }
}