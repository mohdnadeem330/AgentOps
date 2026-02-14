@isTest
public class ECSS_Invocable_BusinessHours_QuoteTest {
 @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a test Company Account
        Account testCompany = new Account(Name = 'Test Company', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bank').getRecordTypeId());
        insert testCompany;
        
        // Create a test Quote Record Type
        String quoteRecordType = System.Label.ECSS_QuoteRecordType;
        Id quoteRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(quoteRecordType).getRecordTypeId();
        
        Assignment_Engine__c engine = new Assignment_Engine__c(
            No_Criteria__c = true, Object_Name__c ='quote'
        );
        insert engine;
        
        // Create test Opportunities
        Opportunity testOpportunity = TestObjectsFactory.getOpportunityRecord(testCompany.Id);
        insert testOpportunity;
        
        Quote testQuote = TestObjectsFactory.getQuoteRecord(testOpportunity.Id);
        insert testQuote;
    }
    
    
    static testMethod void calculateBusinessHours() {
        
        List<Quote> testQuote = [SELECT Id, RecordTypeId,ECSS_SLA_Date__c FROM Quote];
        
        List<ECSS_Invocable_BusinessHours_Quote.Input> requestList = new List<ECSS_Invocable_BusinessHours_Quote.Input>();
        
        ECSS_Invocable_BusinessHours_Quote.Input req = new ECSS_Invocable_BusinessHours_Quote.Input();
        
        req.InputDate = system.now();
        
        req.quoteInput = testQuote[0];
        req.Hours = 24;
        
        requestList.add(req);
        
        Test.startTest();
        ECSS_Invocable_BusinessHours_Quote.calculateBusinessHours(requestList);
        Test.stopTest();
        
    }
    
}