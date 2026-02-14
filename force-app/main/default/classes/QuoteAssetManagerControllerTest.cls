@isTest
public class QuoteAssetManagerControllerTest {

    @isTest
    static void testCreateQuoteLineItems() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

        Product2 product = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id, Status = 'Available', Area__c = 100);
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunityRecord.Id, Pricebook2Id = standardPricebook.Id);
        insert quote;

        // Test createQuoteLineitems method
        Test.startTest();
        QuoteAssetManagerController.createQuoteLineitems(quote.Id, new List<String> { asset.Id });
        Test.stopTest();

        // Verify QuoteLineItem creation
        List<QuoteLineItem> quoteLineItems = [SELECT Id, Product2Id, Quantity, UnitPrice, Asset__c FROM QuoteLineItem WHERE QuoteId = :quote.Id];
    }

    @isTest
    static void testDeleteQuoteLineItems() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;
        
        Product2 product = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id, Status = 'Available', Area__c = 100);
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunityRecord.Id, Pricebook2Id = standardPricebook.Id, Status = 'Signed Lease Agreement');
        insert quote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Asset__c = asset.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1
        );
        insert quoteLineItem;

        Test.startTest();
        QuoteAssetManagerController.deleteQuoteLineItems(quoteLineItem.Id);
        Test.stopTest();

        List<QuoteLineItem> remainingItems = [SELECT Id FROM QuoteLineItem WHERE Id = :quoteLineItem.Id];
    }

    @isTest
    static void testGetProjects() {
        Project__c project = TestObjectsFactory.getProjectRecord('62085');
        insert project;

        Test.startTest();
        List<Project__c> projects = QuoteAssetManagerController.getProjects();
        Test.stopTest();
    }

    @isTest
    static void testGetBuildings() {
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        insert project;

        Test.startTest();
        List<BuildingSection__c> buildings = QuoteAssetManagerController.getBuildings(project.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAssets() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

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

        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        insert project;

        BuildingSection__c building = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert building;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id, Status = 'Available', Building__c = building.Id);
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunityRecord.Id, Pricebook2Id = standardPricebook.Id);
        insert quote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Asset__c = asset.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1
        );
        insert quoteLineItem;

        Test.startTest();
        List<Asset> assets = QuoteAssetManagerController.getAssets(building.Id, quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetQuoteLineItems() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

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

        Asset asset = new Asset(Name = 'Logistic Quote', Product2Id = product.Id, Status = 'Available', Area__c = 100);
        insert asset;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opportunityRecord.Id, Status = 'LOI Signed', Pricebook2Id = standardPricebook.Id);
        insert quote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Asset__c = asset.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1
        );
        insert quoteLineItem;

        Test.startTest();
        quote.LOI_Signing_Date__c = Date.today();
        quote.Status = 'In Progress';
        quote.Received_Booking_Amount__c = true;
        Update quote;
        
        asset.Status = 'Reserved';
        Update asset;
        
        List<QuoteLineItem> quoteLineItems = QuoteAssetManagerController.getQuoteLineItems(quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testCheckAssetAvailabilityForLOI() {
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
}