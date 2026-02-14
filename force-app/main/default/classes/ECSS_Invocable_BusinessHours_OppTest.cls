@isTest
public class ECSS_Invocable_BusinessHours_OppTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a test Company Account
        Account testCompany = new Account(Name = 'Test Company', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bank').getRecordTypeId());
        insert testCompany;
        
        // Create a test Opportunity Record Type
        String oppRecordType = System.Label.ECSS_OpportunityRecordType;
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(oppRecordType).getRecordTypeId();
        
        Assignment_Engine__c engine = new Assignment_Engine__c(
            No_Criteria__c = true, Object_Name__c ='Opportunity'
        );
        insert engine;
        
        // Create test Opportunities
		Opportunity testOpportunity = TestObjectsFactory.getOpportunityRecord(testCompany.Id);
        insert testOpportunity;
    }
    
    
    static testMethod void calculateBusinessHours() {
        
        List<Opportunity> testLeads = [SELECT Id, RecordTypeId,ECSS_SLA_Date__c FROM Opportunity];
        
        List<ECSS_Invocable_BusinessHours_Opp.Input> requestList = new List<ECSS_Invocable_BusinessHours_Opp.Input>();
        
        ECSS_Invocable_BusinessHours_Opp.Input req = new ECSS_Invocable_BusinessHours_Opp.Input();
        
        req.InputDate = system.now();
        
        req.oppInput = testLeads[0];
        req.Hours = 24;
        
        requestList.add(req);
        
        Test.startTest();
        ECSS_Invocable_BusinessHours_Opp.calculateBusinessHours(requestList);
        Test.stopTest();
        
    }
    
}