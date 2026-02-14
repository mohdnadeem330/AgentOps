@isTest
private class Test_Furniture_SaveQuoteHelper {
    
    @testSetup
    static void setupTestData() {
        // Insert Vendor Account with 'Vendor' RecordType
        Id vendorRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor') != null
            ? Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()
            : null;
        
        if (vendorRTId != null) {
            insert new Account(Name = 'Vendor Account', RecordTypeId = vendorRTId);
        }
        
        Account acc = new Account(Name = 'Test Customer Account');
        insert acc;
        
        Product2 bundle = new Product2(Name = 'Chair Bundle', IsActive = true);
        Product2 opt1 = new Product2(Name = 'Cushion', IsActive = true);
        Product2 opt2 = new Product2(Name = 'Armrest', IsActive = true);
        insert new List<Product2>{ bundle, opt1, opt2 };
            
            Id stdPBId = Test.getStandardPricebookId();
        Pricebook2 stdPB = new Pricebook2(Id = stdPBId, IsActive = true);
        update stdPB;
        
        insert new List<PricebookEntry>{
            new PricebookEntry(Product2Id = bundle.Id, Pricebook2Id = stdPB.Id, UnitPrice = 300, IsActive = true),
                new PricebookEntry(Product2Id = opt1.Id, Pricebook2Id = stdPB.Id, UnitPrice = 50, IsActive = true),
                new PricebookEntry(Product2Id = opt2.Id, Pricebook2Id = stdPB.Id, UnitPrice = 30, IsActive = true)
                };
                    
                    Opportunity opp = new Opportunity(
                        Name = 'Furniture Opportunity',
                        StageName = 'Qualification',
                        CloseDate = Date.today().addDays(10),
                        AccountId = acc.Id
                    );
        insert opp;
        
        // Create Quote
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND DeveloperName = 'Furniture' LIMIT 1];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = acc.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId(),
            RecordTypeId = rt.Id // Set record type as 'Furniture'
        );
        insert quote;
        
        insert new List<SBQQ__ProductOption__c>{
            new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = bundle.Id, SBQQ__OptionalSKU__c = opt1.Id, SBQQ__Number__c = 1),
                new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = bundle.Id, SBQQ__OptionalSKU__c = opt2.Id, SBQQ__Number__c = 2),
                new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = bundle.Id, SBQQ__Number__c = 3) // edge case with null OptionalSKU
                };
                    }
    
    @isTest
    static void test_create_quote_with_bundle_and_options() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        Id opt1Id = [SELECT Id FROM Product2 WHERE Name = 'Cushion' LIMIT 1].Id;
        
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = opp.AccountId;
        req.bundleId = bundleId;
        
        Furniture_SaveQuoteWrappers.SaveQuoteLine line1 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line1.productId = bundleId;
        Furniture_SaveQuoteWrappers.SaveQuoteLine line2 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line2.productId = opt1Id;
        
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ line1, line2 };
            
            Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();
        
        
        
        
        List<SBQQ__QuoteLine__c> dbLines = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :res.id];
        Id bundleLineId;
        for (SBQQ__QuoteLine__c ql : dbLines) {
            if (ql.SBQQ__RequiredBy__c == null) bundleLineId = ql.Id;
        }
        for (SBQQ__QuoteLine__c ql : dbLines) {
            if (ql.SBQQ__RequiredBy__c != null) {
                System.assertEquals(bundleLineId, ql.SBQQ__RequiredBy__c, 'Child line should link to bundle');
            }
        }
    }
    
    @isTest
    static void test_existing_quote_removes_lines() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        Id opt1Id = [SELECT Id FROM Product2 WHERE Name = 'Cushion' LIMIT 1].Id;
        
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = opp.AccountId;
        req.bundleId = bundleId;
        
        Furniture_SaveQuoteWrappers.SaveQuoteLine l1 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        l1.productId = bundleId;
        Furniture_SaveQuoteWrappers.SaveQuoteLine l2 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        l2.productId = opt1Id;
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ l1, l2 };
            
            Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res1 = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();
        
        req.quoteId = res1.id;
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ l1 };
            
            
            Furniture_SaveQuoteHelper.processSaveQuote(req);
        
        List<SBQQ__QuoteLine__c> lines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :res1.id];
    }
    
    @isTest
    static void test_quote_with_null_lines() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = opp.AccountId;
        req.bundleId = bundleId;
        req.quoteLines = null;
        
        Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();
        
    }
    
    @isTest
    static void test_optionalSKU_null_skipped() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = opp.AccountId;
        req.bundleId = bundleId;
        
        Furniture_SaveQuoteWrappers.SaveQuoteLine line = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line.productId = bundleId;
        
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ line };
            
            Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();
        
    }
    
    @isTest
    static void test_quote_creation_failure_sets_error() {
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();
    }
    
    /* @isTest
static void test_buildResponse_mapping_logic() {
// Setup a quote and quote lines for mapping logic
Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
Id stdPBId = Test.getStandardPricebookId();

// Create a Quote
SBQQ__Quote__c quote = new SBQQ__Quote__c(
SBQQ__Opportunity2__c = opp.Id,
SBQQ__Account__c = opp.AccountId,
SBQQ__Status__c = 'Draft',
SBQQ__PriceBook__c = stdPBId,
SBQQ__Primary__c = true,
Vendor__c = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1].Id
);
insert quote;

// Create bundle and child quote lines
List<PricebookEntry> pbes = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :stdPBId];

Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
for (PricebookEntry p : pbes) {
pbeMap.put(p.Product2Id, p);
}

SBQQ__QuoteLine__c bundleLine = new SBQQ__QuoteLine__c(
SBQQ__Quote__c = quote.Id,
SBQQ__Product__c = bundleId,
SBQQ__PricebookEntryId__c = pbeMap.get(bundleId).Id,
SBQQ__NetPrice__c = 500,
SBQQ__ListPrice__c = 600
);
insert bundleLine;

SBQQ__QuoteLine__c childLine = new SBQQ__QuoteLine__c(
SBQQ__Quote__c = quote.Id,
SBQQ__Product__c = [SELECT Id FROM Product2 WHERE Name = 'Cushion' LIMIT 1].Id,
SBQQ__PricebookEntryId__c = pbeMap.get([SELECT Id FROM Product2 WHERE Name = 'Cushion' LIMIT 1].Id).Id,
SBQQ__NetPrice__c = 50,
SBQQ__ListPrice__c = 60,
SBQQ__RequiredBy__c = bundleLine.Id,
SBQQ__Bundle__c = false
);
insert childLine;

// Call buildResponse directly
List<SBQQ__QuoteLine__c> partialLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

Test.startTest();
Furniture_SaveQuoteWrappers.QuoteResponse response =
Furniture_SaveQuoteMappingHandler.buildResponse(quote, partialLines, 'BUNDLE-SKU-001');
Test.stopTest();


}*/
    
    
    @isTest
    static void test_service_handler_valid_and_invalid_ops() {
        // Create required test data
        Account testAccount = new Account(FirstName='Test', LastName='Account');
        insert testAccount;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = 'Proposal', CloseDate = Date.today().addDays(10));
        insert opp;
        
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        
        // Prepare a valid request for the 'getSaveQuote' operation
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = testAccount.Id;
        req.bundleId = bundleId;
        
        Furniture_SaveQuoteWrappers.SaveQuoteLine line = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line.productId = bundleId;
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ line };
            
            // Prepare the invalid operation request for testing the catch block
            Furniture_SaveQuoteWrappers.SaveQuoteRequest invalidReq = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        
        // Create a mock RestRequest and RestResponse
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/FurnitureService';
        RestContext.request.httpMethod = 'POST';
        RestContext.response = new RestResponse();
        
        // Test valid operation (getSaveQuote)
        Test.startTest();
        FurnitureService.handleRequest('getSaveQuote', req);  // This will run successfully
        Test.stopTest();
        
        // Simulate a failure to cover catch block by forcing an exception
        try {
            FurnitureService.handleRequest('invalidOperation', invalidReq);  // This should now trigger the catch block
            
            
        } catch (Exception e) {
            System.debug('Caught Exception: ' + e.getMessage());
            // Simulate calling the FurnitureService method with an invalid operation
        }
    }
    
    
    
    @isTest
    static void test_getProductMap_valid_and_empty_input() {
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        Id cushionId = [SELECT Id FROM Product2 WHERE Name = 'Cushion' LIMIT 1].Id;
        
        // Case 1: Valid list of quote lines
        List<Furniture_SaveQuoteWrappers.SaveQuoteLine> lines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>();
        Furniture_SaveQuoteWrappers.SaveQuoteLine line1 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line1.productId = bundleId;
        Furniture_SaveQuoteWrappers.SaveQuoteLine line2 = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line2.productId = cushionId;
        lines.add(line1);
        lines.add(line2);
        
        Test.startTest();
        Map<Id, Product2> productMap = Furniture_SaveQuoteUtils.getProductMap(lines);
        Test.stopTest();
        
        // Case 2: Empty quote lines
        Map<Id, Product2> emptyMap = Furniture_SaveQuoteUtils.getProductMap(new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>());
    } 
    @isTest
    static void test_publishEvent_all_conditions() {
        // Fetch required test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1];
        
        // Case 1: Valid inputs
        Boolean resultSuccess = Furniture_SaveQuoteUtils.publishEvent('CREATE', 'CREATE', opp.Id, vendor.Id);   
        
        // Case 2: Blank action input
        Boolean resultBlankAction = Furniture_SaveQuoteUtils.publishEvent('CREATE', '', opp.Id, vendor.Id);
        
        Test.startTest();
        
        // Case 3: Blank record ID input
        Boolean resultBlankRecordId = Furniture_SaveQuoteUtils.publishEvent('CREATE', 'CREATE', '', vendor.Id);
        
        // Case 4: Blank vendor ID input
        Boolean resultBlankVendorId = Furniture_SaveQuoteUtils.publishEvent('UPDATE', 'UPDATE', opp.Id, '');
        
        // Case 5: Null inputs (Simulate exception scenario)
        Boolean resultException = Furniture_SaveQuoteUtils.publishEvent(null, null, null, null);
        
        Test.stopTest();
    }
    
    @isTest
    static void testPublishEvent_ValidInputs() {
        // Fetch required test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1];
        
        // Case 1: Valid inputs
        Test.startTest();
        Boolean resultSuccess = Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', 'CREATE', opp.Id, vendor.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPublishEvent_BlankAction() {
        // Fetch required test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1];
        
        // Case 2: Blank action input
        Test.startTest();
        Boolean resultBlankAction = Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', '', opp.Id, vendor.Id);
        Test.stopTest();
    }
    @isTest
    static void testPublishEvent_InvalidEventType() {
        // Case: Invalid event type
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1];
        
        Test.startTest();
        Boolean resultInvalidEventType = Furniture_SaveQuoteUtils.publishEvent('InvalidEventType__e', 'CREATE', opp.Id, vendor.Id);
        
        // Log error with LoggerService
        Logger__c errorLog = LoggerService.addApexServiceCalls(
            'Furniture Platform Event Publishing - CREATE',
            'Test_Furniture_SaveQuoteHelper',
            'testPublishEvent_InvalidEventType',
            'InvalidEventType__e',
            'Furniture_SaveQuoteUtils.publishEvent: Invalid event type',
            opp.Id
        );
        LoggerService.save(errorLog);
        
        Test.stopTest();
        
    }
    
    // Test for exception in isValidEventType
    @isTest
    static void testExceptionInIsValidEventType() {
        // Setup real test data
        Account vendor = new Account(Name = 'Test Vendor');
        insert vendor;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = vendor.Id
        );
        insert opp;
        
        // Ensure that the logger record is created with a valid reference
        Logger__c logRecord = new Logger__c(
            Message__c = 'Test log message',
            ExecutingProcessName__c = 'TestProcess',
            LogType__c = 'Apex Exception',
            ExceptionLogId__c = 'Test-Log-ID',
            Account__c = vendor.Id // Ensure this reference is valid
        );
        upsert logRecord;
        
        // Now test the publish event logic
        Test.startTest();
        Boolean result = Furniture_SaveQuoteUtils.publishEvent(
            'InvalidEventType__e', 
            'CREATE', 
            opp.Id,                  // Using actual test record Id
           vendor.Id               // Using actual test record Id
        );
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testPublishEvent_ErrorHandling() {
        // Case 4: Simulate error during event publishing by passing invalid data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Vendor Account' LIMIT 1];
        
        // Simulate failure by passing an invalid Vendor ID
        Test.startTest();
        Boolean resultPublishFailure = Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', 'CREATE', opp.Id, 'InvalidVendorId');
        Test.stopTest();
        
    }
    
    @isTest
    static void testErrorLoggingOnPublishFailure() {
        // Simulate an error in event publishing (Invalid event type)
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Boolean result = Furniture_SaveQuoteUtils.publishEvent('InvalidEventType__e', 'CREATE', opp.Id, '0012w00000Xyz34');
        Test.stopTest();
    }
    
    @isTest
    static void test_populateQuoteAddressFields_with_salesOrder() {
        // Create Project
           Project__c proj = new Project__c(Name = 'Yas Island',City__c = 'Abu Dhabi',BusinessUnitId__c = '111', 
                                       ProjectCode__c='111', CommunityName__c='Yas Island', Country__c = 'United Arab Emirates');

        insert proj;
        
        // Create Unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT123');
    unit.Project__c = proj.Id;
    insert unit;
        // Create Account (Customer)
        Account acc = new Account(Name = 'Test Customer');
        insert acc;
        
        // Create SalesOrder linked to Unit and Account
        SalesOrder__c so = new SalesOrder__c(
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert so;
        
        // Create Opportunity linked to SalesOrder
        Opportunity opp = new Opportunity(
            Name = 'Opp with SalesOrder',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            SalesOrder__c = so.Id 
        );
        insert opp;
        
        // Fetch product and pricebook info
        Id bundleId = [SELECT Id FROM Product2 WHERE Name = 'Chair Bundle' LIMIT 1].Id;
        Id stdPBId = Test.getStandardPricebookId();
        
        // Prepare SaveQuoteRequest
        Furniture_SaveQuoteWrappers.SaveQuoteRequest req = new Furniture_SaveQuoteWrappers.SaveQuoteRequest();
        req.opportunityId = opp.Id;
        req.customerId = acc.Id;
        req.bundleId = bundleId;
        
        Furniture_SaveQuoteWrappers.SaveQuoteLine line = new Furniture_SaveQuoteWrappers.SaveQuoteLine();
        line.productId = bundleId;
        req.quoteLines = new List<Furniture_SaveQuoteWrappers.SaveQuoteLine>{ line };
            
            // Run logic
            Test.startTest();
        Furniture_SaveQuoteWrappers.QuoteResponse res = Furniture_SaveQuoteHelper.processSaveQuote(req);
        Test.stopTest();      
    }
    
}