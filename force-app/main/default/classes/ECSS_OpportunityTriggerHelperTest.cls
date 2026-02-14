@isTest
public class ECSS_OpportunityTriggerHelperTest {

    @isTest
    static void testGetNonLeasingCreatedOpportunityIds() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User nonLeasingUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser1@example.com' + System.currentTimeMillis(),
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert nonLeasingUser;

        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(System.Label.ECSS_OpportunityRecordType)
            .getRecordTypeId();

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = nonLeasingUser.Id,
            RecordTypeId = oppRecordTypeId
        );
        insert opp;

        Assignment_Engine__c engine = new Assignment_Engine__c(
            Object_Name__c = 'Opportunity',
            Criteria__c = 'Test Criteria',
            No_Criteria__c = false
        );
        insert engine;

        Test.startTest();
        List<Id> resultIds = ECSS_OpportunityTriggerHelper.getNonLeasingCreatedOpportunityIds(new List<Opportunity>{opp});
        Test.stopTest();

        System.assertEquals(1, resultIds.size(), 'Expected the opportunity ID to be returned.');
        System.assertEquals(opp.Id, resultIds[0], 'Expected the inserted opportunity ID.');
    }
}