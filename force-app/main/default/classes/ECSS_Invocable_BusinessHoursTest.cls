@isTest
public class ECSS_Invocable_BusinessHoursTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a test Company Account
        Account testCompany = new Account(Name = 'Test Company', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bank').getRecordTypeId());
        insert testCompany;
        
        // Create a test Lead Record Type
        String leadRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(leadRecordType).getRecordTypeId();
        
        Assignment_Engine__c engine = new Assignment_Engine__c(
            No_Criteria__c = true, Object_Name__c ='Lead'
        );
        insert engine;
        
        // Create test Leads
		Lead testLead = TestObjectsFactory.getLeadRecord(1,'ECSS');
        insert testLead;
    }
    
    
    static testMethod void calculateBusinessHours() {
        
        List<Lead> testLeads = [SELECT Id, RecordTypeId, MobilePhone, MobileCountryCode__c, LeadSource, ECSS_SLA_Date__c FROM Lead];
        
        List<ECSS_Invocable_BusinessHours.Input> requestList = new List<ECSS_Invocable_BusinessHours.Input>();
        
        ECSS_Invocable_BusinessHours.Input req = new ECSS_Invocable_BusinessHours.Input();
        
        req.InputDate = system.now();
        
        req.leadInput = testLeads[0];
        req.Hours = 2;
        
        requestList.add(req);
        
        Test.startTest();
        ECSS_Invocable_BusinessHours.calculateBusinessHours(requestList);
        Test.stopTest();
        
    }
    
}