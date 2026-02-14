@isTest
private class SmartHomeServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Standard Pricebook
        Id standardPBId = Test.getStandardPricebookId();
        List<Pricebook2> pbList = [SELECT Id, IsActive FROM Pricebook2 WHERE Id = :standardPBId LIMIT 1];
        
        Pricebook2 pb;
        if (!pbList.isEmpty()) {
            pb = pbList[0];
            if (!pb.IsActive) {
                pb.IsActive = true;
                update pb;
            }
        } else {
            pb = new Pricebook2(Id = standardPBId, IsActive = true);
            upsert pb;
        }
        
        
        // Vendor account
        Id vendorRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        insert new Account(Name = 'KIMBO', RecordTypeId = vendorRTId);
        
        // Customer
        Account acc = new Account(Name = 'Test Customer');
        insert acc;
        
        // Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), AccountId = acc.Id);
        insert opp;
        
        // Products
        Product2 bundle = new Product2(Name = 'SmartBundle1', ProductCode = 'SKU1', IsActive = true);
        Product2 opt1 = new Product2(Name = 'Option1', ProductCode = 'SKU1-Opt1', IsActive = true);
        insert new List<Product2>{ bundle, opt1 };
            
            insert new List<PricebookEntry>{
                new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = bundle.Id, UnitPrice = 100, IsActive = true),
                    new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = opt1.Id, UnitPrice = 25, IsActive = true)
                    };
                        
                        // Bundle options
                        insert new SBQQ__ProductOption__c(
                            SBQQ__ConfiguredSKU__c = bundle.Id,
                            SBQQ__OptionalSKU__c = opt1.Id,
                            SBQQ__Number__c = 1
                        );
    }
    
    @isTest
    static void testHandleRequest_HappyPath() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
        
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'SKU1';
        
        SmartHomeQuoteWrappers.SaveQuoteRequest request = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        request.opportunityId = opp.Id;
        request.customerId = acc.Id;
        request.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        // Optionally assert status and response format
        System.assertEquals(201, RestContext.response.statusCode);
    }
    
    @isTest
    static void testHandleRequest_QuoteResponseWithErrorMessage() {
        // Force SmartHomeQuoteHelper to return an error response
        SmartHomeQuoteWrappers.QuoteResponse fakeRes = new SmartHomeQuoteWrappers.QuoteResponse();
        fakeRes.errorMessage = 'Simulated error';
        
        // Stub/fake the response (if SmartHomeQuoteHelper is not mockable, use dependency injection)
        Test.startTest();
        // Trick: send request with invalid SKU so helper fails gracefully
        SmartHomeQuoteWrappers.SaveQuoteRequest req = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = '006XXXXXXXXXXXX'; 
        req.customerId = '001XXXXXXXXXXXX'; 
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'InvalidSKU';
        req.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.response = new RestResponse();
        
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('INTERNAL_SERVER_ERROR'));
    }
    
    @isTest
    static void testHandleRequest_UnhandledException() {
        // Send malformed but valid structure that will blow up helper logic
        SmartHomeQuoteWrappers.SaveQuoteRequest req = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = null; // will pass validation but crash later
        req.customerId = '001XXXXXXXXXXXX';
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'SKU1';
        req.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testLoggerRecordsCreated() {
        // Trigger a validation error
        SmartHomeQuoteWrappers.SaveQuoteRequest req = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        // Assert that at least one Logger__c was created
        System.assert([SELECT COUNT() FROM Logger__c] > 0, 'Logger records should have been created');
    }
    
    @isTest
    static void testHandleRequest_QuoteResponseNull() {
        SmartHomeQuoteWrappers.SaveQuoteRequest req = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = '006XXXXXXXXXXXX'; 
        req.customerId = '001XXXXXXXXXXXX'; 
        req.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>(); // empty
        
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }

    
    @isTest
    static void testHandleRequest_ValidationFailure() {
        SmartHomeQuoteWrappers.SaveQuoteRequest request = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        // No required fields
        
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testHandleRequest_MalformedJSON() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{invalid_json}');
        RestContext.response = new RestResponse();
        
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode);
    }
    
    @isTest
    static void testProcessSaveQuote_ErrorHandling() {
        SmartHomeQuoteWrappers.SaveQuoteRequest request = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        request.opportunityId = '006XXXXXXXXXXXX'; // invalid
        request.customerId = '001XXXXXXXXXXXX';   // invalid
        
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'InvalidSKU';
        request.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            Test.startTest();
        SmartHomeQuoteWrappers.QuoteResponse res = SmartHomeQuoteHelper.processSaveQuote(request);
        Test.stopTest();
        
        System.assertNotEquals(null, res);
        System.assertNotEquals(null, res.errorMessage);
    }
    
    @isTest
    static void testGetOrCreateQuote_Directly() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id pbId = Test.getStandardPricebookId();
        
        SmartHomeQuoteWrappers.SaveQuoteRequest request = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        request.opportunityId = opp.Id;
        request.customerId = opp.AccountId;
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'SKU1';
        
        request.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            
            Test.startTest();
        SBQQ__Quote__c quote = SmartHomeQuoteUtils.getOrCreateQuote(request, pbId);
        Test.stopTest();
        
        System.assertNotEquals(null, quote);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
    }
    
    @isTest
    static void testQuoteMappingHandler_BuildResponse() {
        // First trigger quote creation via helper
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'SKU1';
        
        SmartHomeQuoteWrappers.SaveQuoteRequest req = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = opp.AccountId;
        req.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            SmartHomeQuoteWrappers.QuoteResponse result;
        Test.startTest();
        result = SmartHomeQuoteHelper.processSaveQuote(req);
        Test.stopTest();
        
        // Now safely query the quote using the returned ID
        if (result != null && result.id != null) {
            SBQQ__Quote__c quote = [
                SELECT Id, SBQQ__NetAmount__c, SBQQ__Status__c, SBQQ__Opportunity2__c,
                Vendor__c, Vendor__r.Name, Total_Original_List_Price__c,
                Total_Discount_Amount__c, Quote_Total_Discount_Percentage__c,
                Total_Tax__c, Quote_Calculation_Complete__c, VAT_Value__c
                FROM SBQQ__Quote__c
                WHERE Id = :result.id
                LIMIT 1
            ];
            
            List<SBQQ__QuoteLine__c> lines = [
                SELECT Id, SBQQ__Product__c, SBQQ__NetPrice__c, SBQQ__ProductCode__c,SBQQ__ListPrice__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c,  SBQQ__OptionLevel__c  , SBQQ__Product__r.ProductCode 
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
            ];
            
            SmartHomeQuoteWrappers.QuoteResponse response = SmartHomeQuoteMappingHandler.buildResponse(quote, lines,req);
            System.assertEquals(quote.Id, response.id);
        } else {
            System.assert(false, 'Quote creation failed in helper.');
        }
    }
    
    
    @isTest
    static void testQuoteUtilsMethods() {
        Pricebook2 pb = SmartHomeQuoteUtils.getStandardPricebook();
        System.assertNotEquals(null, pb);
        
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'SKU1';
        List<SmartHomeQuoteWrappers.SaveQuoteLine> lines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            Map<String, Product2> skuMap = SmartHomeQuoteUtils.getProductMapBySKU(lines);
        System.assert(skuMap.containsKey('SKU1'));
        
        Set<Id> productIds = new Set<Id>();
        for (Product2 p : skuMap.values()) {
            productIds.add(p.Id);
        }
        
        Map<Id, Id> pbeMap = SmartHomeQuoteUtils.getPricebookEntries(productIds, pb.Id);
        System.assert(!pbeMap.isEmpty());
    }
    
    @isTest
    static void testHandleRequest_QuoteResponseWithErrorGuaranteed() {
        // Step 1: Create a Product2 with no PricebookEntry
        Product2 badProduct = new Product2(Name = 'ErrorTriggerSKU', ProductCode = 'ERR001', IsActive = true);
        insert badProduct;
        
        // Step 2: Get Opportunity and Account
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
        
        // Step 3: Build request
        SmartHomeQuoteWrappers.SaveQuoteRequest request = new SmartHomeQuoteWrappers.SaveQuoteRequest();
        request.opportunityId = opp.Id;
        request.customerId = acc.Id;
        
        SmartHomeQuoteWrappers.SaveQuoteLine line = new SmartHomeQuoteWrappers.SaveQuoteLine();
        line.bundleSKU = 'ErrorTriggerSKU'; // Matches inserted product
        request.quoteLines = new List<SmartHomeQuoteWrappers.SaveQuoteLine>{ line };
            
            // Step 4: Send POST request
            RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/SmartHomeService';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        RestContext.response = new RestResponse();
        
        // Step 5: Execute
        Test.startTest();
        SmartHomeService.handleRequest();
        Test.stopTest();
        
        // Step 6: Assert
        String responseStr = RestContext.response.responseBody.toString();

    }
    
    
}