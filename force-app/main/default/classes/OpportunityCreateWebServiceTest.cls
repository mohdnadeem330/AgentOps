@isTest
public class OpportunityCreateWebServiceTest {
    
    @isTest
    static void testcase1(){
            
        Account accountRecord = TestObjectsFactory.getPersonAccountRecord();
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        
		TestObjectsFactory.initializeRestContext(null, '/upsert/opportunity');

        OpportunityCreateWebService.doPost(oppRecord,accountRecord,null,true);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        OpportunityCreateWebService.doPost(oppRecord,accountRecord,null,true);
    }

    @isTest
    static void testcase2(){
            
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('Company','12333');
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        
		TestObjectsFactory.initializeRestContext(null, '/upsert/opportunity');

        OpportunityCreateWebService.doPost(oppRecord,accountRecord,null,false);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        OpportunityCreateWebService.doPost(oppRecord,accountRecord,null,false);
    }
}