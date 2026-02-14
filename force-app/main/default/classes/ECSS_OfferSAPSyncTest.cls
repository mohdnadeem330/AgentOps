@isTest
public class ECSS_OfferSAPSyncTest {

    @testSetup
    static void setupData() {
        // Create a Pricebook (if required for Quote)
        Pricebook2 pb = new Pricebook2(Name = 'Test PB', IsActive = true);
        insert pb;
        
        Account testCompany = new Account(Name = 'Test Company', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bank').getRecordTypeId());
        insert testCompany;
        
        // Create test Opportunities
        Opportunity testOpportunity = TestObjectsFactory.getOpportunityRecord(testCompany.Id);
        insert testOpportunity;

        // Create a Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            Status = 'Draft',
            Pricebook2Id = pb.Id,
            OpportunityId = testOpportunity.id
        );
        insert q;
    }

    @isTest
    static void testFlipFlagAndReset() {
        Quote q = [SELECT Id, ECSS_SAPSync__c FROM Quote LIMIT 1];

        // Call method
        Test.startTest();
        ECSS_OfferSAPSync.flipFlag(new List<Id>{ q.Id });
        Test.stopTest(); // this executes the Queueable as well

        // Re-query after Queueable execution
        q = [SELECT Id, ECSS_SAPSync__c FROM Quote WHERE Id = :q.Id];

        // Final state should be false (because reset job runs)
        System.assertEquals(false, q.ECSS_SAPSync__c, 'Flag should be reset to false after Queueable runs');
    }

    @isTest
    static void testFlipFlagOnly() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        // Run only the flip method, but don't let queueable execute
        Test.startTest();
        ECSS_OfferSAPSync.flipFlag(new List<Id>{ q.Id });
        // Do not call stopTest yet (queueable not executed)
        Test.stopTest();

        // Actually, queueable runs at stopTest, so to check intermediate "true" flag,
        // we must do it in separate method or split test:
        // Here, simulate by calling Queueable directly:
        Quote q1 = [SELECT Id, ECSS_SAPSync__c FROM Quote WHERE Id = :q.Id];
        
    }
}