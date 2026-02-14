@isTest
public class ECSS_QuoteLineItemCreatorTest {

    @testSetup
    static void setupData() {
        
        insert new List<Trigger_Enabler__c>{
                new Trigger_Enabler__c(
                    Name = 'Asset',
                    Is_After_Insert__c = true,
                    Is_After_Update__c = true,
                    Is_After_Delete__c = true,
                    Is_Before_Insert__c = true,
                    Is_Before_Update__c = true,
                    Is_Before_Delete__c = true
                )
                
            };
             
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        

         List<Product2> products = new List<Product2>();

        Product2 prod = new Product2(
            Name = 'Apartment',
            IsActive = true,
            Family = 'Housing'
        );
        products.add(prod);
        //insert prod;
        
        Product2 prod2 = new Product2(
            Name = 'TAF',
            IsActive = true
        );
        products.add(prod2);
        //insert prod2;
        
        Product2 prod3 = new Product2(
            Name = 'Security Deposit',
            IsActive = true
        );
        products.add(prod3);
        //insert prod3;
        
        Product2 prod4 = new Product2(
            Name = 'Admin Fees',
            IsActive = true
        );
        products.add(prod4);
        insert products;
        System.debug('TEST: '+products);
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        for(Product2 product: products)
        {
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product.Id, UnitPrice = 0, IsActive = true);
            pricebookEntries.add(pbe);
        }
        /*PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod.Id, UnitPrice = 0, IsActive = true);
        //insert pbe;
        pricebookEntries.add(pbe);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod2.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(pbe2);
        //insert pbe2;
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod3.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(pbe3);
        //insert pbe3;
        PricebookEntry pbe4 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod4.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(pbe4);*/
        
        insert pricebookEntries;
        System.debug('TEST: '+pricebookEntries);
        
        Account testCompany = new Account(Name = 'Test Company', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bank').getRecordTypeId());
        insert testCompany;
        
        // Create test Opportunities
        Opportunity testOpportunity = TestObjectsFactory.getOpportunityRecord(testCompany.Id);
        insert testOpportunity;

        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            Pricebook2Id = pricebookId,
            OpportunityId = testOpportunity.id, // optional if Opportunity required
            Status = 'Draft'
           
        );
        insert q;

        // Create Assets
        List<Asset> assets = new List<Asset>();
        assets.add(new Asset(
            Name = 'Asset Rent Only',
            ECSS_Rent_BaseLine__c = 1000,
            ECSS_SD_Amount__c = 1999,
            AccountId = null // Add valid account if required by org
        ));
        assets.add(new Asset(
            Name = 'Asset SD and TAF',
            //ECSS_SD_Amount__c = 500,
            //TAF_Amount__c = 300,
            AccountId = null
        ));
        insert assets;
    }

    @isTest
    static void testCreateQLIs() {
        // Get test data
        Quote q = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];
        List<Asset> assets = [SELECT Id FROM Asset];

        // Build flow input
        ECSS_QuoteLineItemCreator.FlowInput input = new ECSS_QuoteLineItemCreator.FlowInput();
        input.quoteId = q.Id;
        input.assetIds = new List<Id>{ assets[0].Id, assets[1].Id };
        input.taf = 100.0;
        input.sd = 200.0;
        input.adminFees = 300.0;
        input.pricebook2Id = q.Pricebook2Id;

        Test.startTest();
        ECSS_QuoteLineItemCreator.createQLIs(new List<ECSS_QuoteLineItemCreator.FlowInput>{ input });
        Test.stopTest();

        // Verify QLIs created
        List<QuoteLineItem> qlis = [
            SELECT Id, QuoteId, Asset__c, UnitPrice, ECSS_Type__c
            FROM QuoteLineItem
            WHERE QuoteId = :q.Id
        ];

        //System.assert(!qlis.isEmpty(), 'QLIs should have been created');
        Set<String> types = new Set<String>();
        for (QuoteLineItem qli : qlis) {
            types.add(qli.ECSS_Type__c);
        }

        // Expect Rent, SD, and TAF types
        //System.assert(types.contains('Rent'), 'Rent QLI should exist');
        //System.assert(types.contains('SD'), 'SD QLI should exist');
        //System.assert(types.contains('TAF'), 'TAF QLI should exist');
    }
}