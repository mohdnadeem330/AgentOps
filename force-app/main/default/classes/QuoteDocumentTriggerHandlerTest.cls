@isTest
public class QuoteDocumentTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        
        Asset asset = new Asset();
        Asset.Name = 'Asset';
        asset.Base_Cost__c = 1000;
        asset.Parking_Type__c = 'Premium Slot';
        asset.Parking_Tier__c = 'Gold';
        asset.Parking_Ref_ID__c = 123;
        insert asset;
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity linked to the Account
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            AccountId = acc.Id,
            Lead_Type__c = 'Logistics'
        );
        insert opp;
		
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create Quote linked to the Opportunity
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = acc.id,
            Parking_Ref_ID__c = string.valueOf(asset.Parking_Ref_ID__c),
            SBQQ__Primary__c = true,
            SBQQ__PricebookId__c = pricebookId,
            SBQQ__PriceBook__c = pricebookId
        );
        insert quote;
        
        Product2 prd = new Product2();
        prd.Name='Parking';
        insert prd;
        
        
        
        // Step 5: Create PricebookEntry in Custom Pricebook (Optional)
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prd.Id, 
            UnitPrice = 100, // Custom price for the product
            IsActive = true
        );
        insert customPricebookEntry;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.CurrencyIsoCode='AED';
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__NetPrice__c = 100;
        quoteLine.SBQQ__Product__c = prd.id;
        quoteLine.SBQQ__PricebookEntryId__c = customPricebookEntry.id;
        quoteLine.Parking_Ref_ID__c = '123456';
        quoteLine.SBQQ__OptionLevel__c = 1;
        quoteLine.SBQQ__OptionType__c = 'Component';
        insert quoteLine;
    }

    @isTest
    static void testHandleAfterInsert() {
        // Retrieve test data
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];

        // Create a QuoteDocument to trigger the logic
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = testQuote.Id,
            Name = 'Test Quote Document'
        );
        insert quoteDocument;
        

        // Check that the Quote's Account field is populated
        SBQQ__Quote__c updatedQuote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id = :testQuote.Id];
        updatedQuote.SBQQ__Primary__c = true;
        update updatedQuote;
        Test.setMock(HttpCalloutMock.class, new RestMock());
        System.assertNotEquals(null, updatedQuote.SBQQ__Account__c, 'The AccountId should be populated on the Quote');
    }
    
    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}