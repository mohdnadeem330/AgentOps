@IsTest
public class ECSS_QuoteTriggerTest {
    

    @IsTest
     static void test_syncSAP_and_publishOfferEvents() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Quote Released',
            OpportunityId = opp.Id,
            Status = 'Draft',
            ECSS_OfferStatus__c = 'Released'
        );
        insert q;

        Quote oldQ = q.clone(false, true, true, true);
        oldQ.ECSS_OfferStatus__c = 'Pending';

        User testUser = [SELECT Id, UserType FROM User WHERE IsActive = true LIMIT 1];
        System.assertNotEquals(null, testUser);

        Test.startTest();
        QuoteTriggerHelper.syncSAP(new List<Quote>{q}, new Map<Id, Quote>{q.Id => oldQ});
        QuoteTriggerHelper.publishOfferEvents(new List<Quote>{q}, new Map<Id, Quote>{q.Id => oldQ});
        Test.stopTest();

        Quote updatedQuote = [SELECT ECSS_SAPSync__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(true, updatedQuote.ECSS_SAPSync__c);
    }
@isTest
    static void testCreateQuoteDocuments() {
        Account account = new Account(Name = 'Test Company');
        insert account;

        Opportunity opportunity = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opportunity;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunity.Id,Pricebook2Id = standardPricebook.Id, RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Logistics').getRecordTypeId());
        insert quote;

        Test.startTest();
        QuoteTriggerHelper.createQuoteDocuments(new List<Quote> { quote });
        Test.stopTest();
    }
    
      @isTest
    static void testUpdateLOISigningDate() {
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Account account = new Account(Name = 'Test Company');
        insert account;

        Opportunity opportunity = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opportunity;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunity.Id, Pricebook2Id = standardPricebook.Id);
        insert quote;

        Quote oldQuote = new Quote(Id = quote.Id, Status = 'Draft');

        Test.startTest();
        quote.Status = 'LOI Signed';
        QuoteTriggerHelper.updateLOISigningDate(new List<Quote> { quote }, new Map<Id, Quote> { oldQuote.Id => oldQuote });
        Test.stopTest();
    }
 
    @isTest
    static void testUpdateAssetStatusForLOI() {
        
          Insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );

        Account account = new Account(Name = 'Test Company');
        insert account;

        Opportunity opportunity = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opportunity;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id, Status = 'Available');
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunity.Id, Pricebook2Id = standardPricebook.Id);
        insert quote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(QuoteId = quote.Id, Product2Id = product.Id, PricebookEntryId = pbe.Id, UnitPrice = 100, Asset__c = asset.Id, Quantity = 1);
        insert quoteLineItem;

        Quote oldQuote = new Quote(Id = quote.Id, Status = 'Draft');

        Test.startTest();
        quote.Status = 'LOI Signed';
        QuoteTriggerHelper.updateAssetStatusForLOI(new List<Quote> { quote }, new Map<Id, Quote> { oldQuote.Id => oldQuote });
        Test.stopTest();
    }
@isTest
    static void testCheckAssetAvailabilityForLOI() {
        Insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );
        
        Account account = new Account(Name = 'Test Company');
        insert account;

        Opportunity opportunity = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opportunity;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id, Status = 'Available');
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunity.Id, Pricebook2Id = standardPricebook.Id);
        insert quote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(QuoteId = quote.Id, Product2Id = product.Id, PricebookEntryId = pbe.Id, UnitPrice = 100, Asset__c = asset.Id, Quantity = 1);
        insert quoteLineItem;

        Quote newQuote = [SELECT Id, Status FROM Quote WHERE Id = :quote.Id];
        newQuote.Status = 'LOI Signed';

        Quote oldQuote = new Quote(Id = newQuote.Id, Status = 'Draft');

        Test.startTest();
        QuoteTriggerHelper.checkAssetAvailabilityForLOI(
            new List<Quote>{ newQuote }, 
            new Map<Id, Quote>{ oldQuote.Id => oldQuote }
        );
        Test.stopTest();        
    }
}