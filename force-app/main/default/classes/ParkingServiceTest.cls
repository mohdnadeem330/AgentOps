@isTest
public class ParkingServiceTest {
    
    @isTest
    static void testGetPropertiesList() {
        // Set up test data
        createTestData();

        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getPropertiesList');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
         Test.startTest();
        ParkingService.getRequest();
		Test.stopTest();
        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);
        //System.assert(res.responseBody.toString().contains('communityName'));
    }
    
     @isTest
    static void testGetOpportunities() {
        // Set up test data
        createTestData();

        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getOpportunities');
        req.params.put('customerId', 'testCustomerId');
        req.params.put('recordType', 'Premium Parking');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
        ParkingService.getRequest();

        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);

    }
    
   
    @isTest
    static void testGetPremiumInvList() {
        // Set up test data
        createTestData();

        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getPremiumInvList');
        req.params.put('customerId', 'testCustomerId');
        req.params.put('community', 'Yas Island');
        req.params.put('projectName', 'Yas Island');
        req.params.put('building', 'B1');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
        Test.startTest();
        ParkingService.getRequest();
        Test.stopTest();

        // Verify the response
        RestResponse res = RestContext.response;
        //System.assertNotEquals(null, res.responseBody);
        //System.assert(res.responseBody.toString().contains('communityName'));
    }

    @isTest
    static void testGetAddOns() {
        // Set up test data
        createTestData();

        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getAddOns');
        req.params.put('customerId', 'testCustomerId');
        req.params.put('parkingRefId', 'Ref123');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
        ParkingService.getRequest();
        
         Test.startTest();
        ParkingService.ParkingDetails result = ParkingService.getAddOns('testCustomerId', 'Ref123');
        Test.stopTest();

        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);
    }

    @isTest
    static void testGetQuoteAndLineItems() {
        // Set up test data
            setupTestData1();
         Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Class-A');
    insert account;
    String customerId = account.Id;
        
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    insert opp;

    Project__c project = TestObjectsFactory.getProjectRecord('Mayan');
    insert project;
     Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT123');
    unit.Project__c = project.Id;
    insert unit;

    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
         string customerId1 = [SELECT Id FROM Account LIMIT 1].Id;
        string quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
       SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        String salesOrderId = so.Id;
        
        
        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getQuoteandLineItems');
        req.params.put('customerId', customerId1);
         req.params.put('SalesOrderId', salesOrderId);
        req.params.put('quoteId', quoteId);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
       
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new RestMock());
 ParkingService.getRequest();
        Test.stopTest();

        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);
    }

    @isTest
    static void testGetQuoteAndLineItems2() {
        // Set up test data
            setupTestData1();
         Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Class-A');
    insert account;
    String customerId = account.Id;

    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    insert opp;

    Project__c project = TestObjectsFactory.getProjectRecord('Mayan');
    insert project;
     Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT123');
    unit.Project__c = project.Id;
    insert unit;

    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
         string customerId1 = [SELECT Id FROM Account LIMIT 1].Id;
        string quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
       SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        String salesOrderId = so.Id;
        System.debug('salesOrderId' + salesOrderId);
        
        
        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getQuoteandLineItems');
         req.params.put('SalesOrderId', salesOrderId);
                req.params.put('customerId', customerId1);


        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
       
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new RestMock());
 ParkingService.getRequest();
        Test.stopTest();

        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);
    }

      @isTest
    static void testGetQuoteAndLineItems3() {
        // Set up test data
            setupTestData1();
         Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Class-A');
    insert account;
    String customerId = account.Id;

    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    insert opp;

    Project__c project = TestObjectsFactory.getProjectRecord('Mayan');
    insert project;
     Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT123');
    unit.Project__c = project.Id;
    insert unit;

    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
         string customerId1 = [SELECT Id FROM Account LIMIT 1].Id;
        string quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
       SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        String salesOrderId = so.Id;
        
        
        // Create a mock request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'getQuoteandLineItems');
                req.params.put('customerId', customerId1);


        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call the method
       
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new RestMock());
 ParkingService.getRequest();
        Test.stopTest();

        // Verify the response
        RestResponse res = RestContext.response;
        System.assertNotEquals(null, res.responseBody);
    }

    public static void createTestData() {
        // Create any necessary test data here (e.g., Asset, SBQQ__Quote__c, etc.)
        // For example, you can insert a few Asset records
        List<Asset> assets = new List<Asset>();
        
        Project__c pu = new Project__c(Name = 'Yas Island',City__c = 'Abu Dhabi',BusinessUnitId__c = '111', 
                                       ProjectCode__c='111', CommunityName__c='Yas Island', Country__c = 'United Arab Emirates');
        insert pu;

        BuildingSection__c bu= new BuildingSection__c();
        bu.BuildingSectionCode__c = 'B1';
        bu.Name ='B1';
        bu.Project__c = pu.Id;
        insert bu;
        
          Product2 prd = new Product2();
        prd.Name='Parking';
        insert prd;
        
        
       
        
        Product2 prd1 = new Product2();
        prd1.Name='Premium Slot';
        insert prd1;
        
        Product2 prd2 = new Product2();
        prd2.Name='Gold';
        insert prd2;
        
       // RecordType lrc = [select id from recordtype where Name='Lead' and sobjectType='Product_Configuraton__c'];

                Id lrc = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Lead').getRecordTypeId();

        Product_Configuraton__c pc = new Product_Configuraton__c();
        pc.RecordTypeId = lrc;
        pc.Project__c = pu.id;
        //pc.Product__c = ;
        pc.Cost__c = 123;
        pc.Margin__c = 10;
        pc.Building__c = bu.id;
        pc.Parking_Type__c = 'Premium Slot';
        pc.Parking_Tier__c = 'Gold';
        insert pc;
        // Assume required fields are populated, adjust as needed
        // 
        //        RecordType rec1 = [select id from recordtype where Name='Premium Parking' and sobjectType='Asset'];
        Id parkingRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Premium Parking').getRecordTypeId();
        

        assets.add(new Asset(Name = 'Test Asset 1', Project__c = pu.id, Building__c=bu.id, Status='Available',
                            Distance_From_Lobby_in_m__c= '10',
                             Product2Id = prd.Id,
                           Capacity__c=1, 
                             Parking_Type__c='Premium Slot',
                            Parking_Tier__c='Gold',
                             Parking_Group__c = 'Group A',
            				Parking_Segment__c = 'Segment 1',
                             List_Price__c = 500.0,
                             Ref_ID__c = 'Ref123',
            				Parking_Category__c = 'Parking',
                             Recordtypeid=parkingRecordTypeId,
                            Parking_Ref_ID__c=101,Base_Cost__c = 10000));
        insert assets;
        
      
        
        SBQQ__ProductFeature__c pf = new SBQQ__ProductFeature__c();
        pf.Name = 'Parking Type';
        pf.SBQQ__ConfiguredSKU__c = prd.id;
        pf.SBQQ__MaxOptionCount__c = 1;
        pf.SBQQ__MinOptionCount__c = 0;
        pf.SBQQ__Number__c = 5;
        pf.SBQQ__OptionSelectionMethod__c = 'Click';
        insert pf;
        
        SBQQ__ProductFeature__c pf1 = new SBQQ__ProductFeature__c();
        pf1.Name = 'ParkingTier';
        pf1.SBQQ__ConfiguredSKU__c = prd.id;
        pf1.SBQQ__MaxOptionCount__c = 1;
        pf1.SBQQ__MinOptionCount__c = 0;
        pf1.SBQQ__Number__c = 10;
        pf1.SBQQ__OptionSelectionMethod__c = 'Click';
        insert pf1;
        
        SBQQ__ProductOption__c po = new SBQQ__ProductOption__c();
        po.SBQQ__ConfiguredSKU__c = prd.id;
        po.SBQQ__Feature__c = pf.id;
        po.SBQQ__Number__c = 5;
        po.SBQQ__OptionalSKU__c = prd1.id;
        po.SBQQ__QuantityEditable__c = true;
        po.SBQQ__Quantity__c = 1;
        po.SBQQ__Type__c = 'Component';
        insert po;
        
        
        
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Id pricebookId = Test.getStandardPricebookId();
       // RecordType rc = [select id from RecordType where SobjectType='Opportunity' and name='New Sale'];
                Id rc = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sale').getRecordTypeId();

        
        // Create an Opportunity and related Quote
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            AccountId = acc.Id,
            Lead_Type__c = 'Logistics',
            Pricebook2Id = pricebookId
            //RecordTypeId = rc,
            //Project__c = 'Yas Island'
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = acc.id,
            SBQQ__Primary__c = true,
            Parking_Ref_ID__c = '101',
            SBQQ__Status__c = 'Draft',
            Parking_Tier__c ='Gold',
            Parking_Type__c = 'Premium Slot',
            SBQQ__PriceBook__c = pricebookId,
            Parking_Group__c = 'Test Group',
            Parking_Segment__c = 'Test Segment',
            Parking_Category__c = 'Test Category'
        );
        insert quote;
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prd.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        SBQQ__QuoteTemplate__c qt = new SBQQ__QuoteTemplate__c (Name='Aldar',SBQQ__CompanyName__c='Aldar Properties',SBQQ__DeploymentStatus__c='Deployed',SBQQ__TermsConditionsTitle__c='Terms & Conditions');
        insert qt;
        
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.CurrencyIsoCode='AED';
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__NetPrice__c = 100;
        quoteLine.SBQQ__ListPrice__c = 100;
        quoteLine.SBQQ__Product__c = prd.id;
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
        quoteLine.Parking_Ref_ID__c = '101';
        quoteLine.SBQQ__OptionLevel__c = 1;
        quoteLine.SBQQ__OptionType__c = 'Component';
        insert quoteLine;
        // Insert other related records as needed (like SBQQ__Quote__c, SBQQ__QuoteLine__c, etc.)
        // Ensure to create test records that will be returned by the service methods
    }
    
     @IsTest
    static void testHandleRequest_createLeadAndConvert() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'POST';
        
        // Prepare mock lead input
        ParkingService.LeadInput leadInfo = new ParkingService.LeadInput();
        leadInfo.FirstName = 'John';
        leadInfo.LastName = 'Doe';
        leadInfo.Email = 'john.doe@example.com';
        leadInfo.MobileNumber1 = '1234567890';
        leadInfo.MobileCountryCode = '1';
        leadInfo.CountryOfResidence = 'US';
        leadInfo.Project = 'Yas Island';

        // Set lead input in request body
        req.requestBody = Blob.valueOf(JSON.serialize(leadInfo));
        req.addParameter('operation', 'createLeadAndConvert');
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ParkingService.handleRequest('createLeadAndConvert', null, null, null, null, null, null, leadInfo, null, null,null,null,null);
        Test.stopTest();
        
        // Verify response
        System.assertEquals(201, res.statusCode);
        System.assert(res.responseBody != null, 'Response body should not be null');
        System.debug('Lead Conversion Response: ' + res.responseBody.toString());
    }
    
    
        @isTest
    static void testCreateLeadAndConvertSuccess() {
        // Step 1: Setup Test Data
        // Create a required Project record for the Lead

        Project__c project = new Project__c(Name = 'Test Project',City__c = 'Abu Dhabi',BusinessUnitId__c = '111', 
                                       ProjectCode__c='111', CommunityName__c='Yas Island', Country__c = 'United Arab Emirates');
        insert project;
        
        // Create required Pricebook2 record (Standard Price Book)
        Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
        insert pb;

        
        
        // Create LeadInput data
        ParkingService.LeadInput leadInput = new ParkingService.LeadInput();
        leadInput.FirstName = 'John';
        leadInput.LastName = 'Doe';
        leadInput.Email = 'john.doe@example.com';
        leadInput.MobileNumber1 = '1234567890';
        leadInput.MobileCountryCode = '971';
        leadInput.CountryOfResidence = 'United Arab Emirates';
        leadInput.Nationality = 'United Arab Emirates';
        leadInput.LeadOrigin = 'United Arab Emirates';
        leadInput.Project =  'Grove Beach Views'; ///project.Id; 
        leadInput.State = 'Abu Dhabi'; 
        leadInput.Country = 'United Arab Emirates';
        leadInput.PropertyUsage = 'Residential Sale'; 
        leadInput.CustomerLocation = 'Abu Dhabi'; 
        leadInput.SalesType = 'Residential Sale'; 
        leadInput.LeadSource = 'Online';
        leadInput.EnquiryCategory = 'Aldar Websites'; 
        leadInput.EnquiryTrigger = 'Live Aldar';
        leadInput.SalesOrigin = 'Domestic'; 
        leadInput.ResidentStatus = 'Resident';
        leadInput.Lead_Type = 'Options and Upgrades'; 
        leadInput.LeadSubType = 'Premium Parking'; 

        // Step 2: Test Method Execution
        Test.startTest();
        ParkingService.LeadResponse response = ParkingService.createLeadAndConvert(leadInput);
        Test.stopTest();

        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), 
                                                      AccountId = testAccount.Id, Lead_Type__c = 'Logistics');
        insert testOpportunity;

    } 
    
    
  
    
    static void setupTestData() {
        // Create necessary test data for Quote, Opportunity, etc.
        
        BuildingSection__c bu= new BuildingSection__c();
        bu.BuildingSectionCode__c = 'B1';
        bu.Name ='B1';
        insert bu;
        
        Project__c pu = new Project__c(Name = 'Yas Island',City__c = 'Abu Dhabi',BusinessUnitId__c = '111', 
                                       ProjectCode__c='111', CommunityName__c='Yas Island', Country__c = 'United Arab Emirates');
        insert pu;
        
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Id pricebookId = Test.getStandardPricebookId();
        
       // RecordType rc = [select id from RecordType where SobjectType='Opportunity' and name='Premium Parking'];
               Id rc = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Premium Parking').getRecordTypeId();
 
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), 
                                                      AccountId = testAccount.Id, Lead_Type__c = 'Logistics');
        insert testOpportunity;

        //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        
        
        
        Product2 product = new Product2(Name = 'Parking', IsActive = true);
        insert product;
        
        Product2 product1 = new Product2(Name = 'Premium Gold', IsActive = true);
        insert product1;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        Asset testAsset = new Asset(Name = 'Test Asset', 
                                    Product2Id = product.Id, 
                                    AccountId = testAccount.Id, 
                                    Parking_Type__c = 'Premium Slot', 
                                    Parking_Tier__c = 'Gold', 
                                    Parking_Ref_ID__c = 101,
                                    Status='Available',
                                    Distance_From_Lobby_in_m__c= '10', 
                                    Capacity__c=1,
                                    Project__c = pu.id,
                                    Building__c = bu.id);
        insert testAsset;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__Account__c = testAccount.Id, SBQQ__Status__c = 'Draft'
                                                    //  , Parking_Type__c = 'Premium Slot', Parking_Tier__c = 'Gold'
                                                     ,SBQQ__Primary__c = true,
            Parking_Ref_ID__c = '101',SBQQ__PricebookId__c = pricebookId,
            SBQQ__PriceBook__c = pricebookId);
        insert testQuote;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.CurrencyIsoCode='AED';
        quoteLine.SBQQ__Quote__c = testQuote.Id;
        quoteLine.SBQQ__NetPrice__c = 100;
        quoteLine.SBQQ__Product__c = product.id;
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
        quoteLine.Parking_Ref_ID__c = '123456';
        quoteLine.SBQQ__OptionLevel__c = 1;
        quoteLine.SBQQ__OptionType__c = 'Component';
        insert quoteLine;
    }
    
     static void setupTestData1() {
        // Create necessary test data for Quote, Opportunity, etc.
        
        Project__c pu = new Project__c(Name = 'Yas Island',City__c = 'Abu Dhabi',BusinessUnitId__c = '111', 
                                       ProjectCode__c='111', CommunityName__c='Yas Island', Country__c = 'United Arab Emirates');
        insert pu;

        BuildingSection__c bu= new BuildingSection__c();
        bu.BuildingSectionCode__c = 'B1';
        bu.Name ='B1';
        bu.Project__c = pu.Id;
        insert bu;
        
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Id pricebookId = Test.getStandardPricebookId();
        //RecordType rc = [select id from RecordType where SobjectType='Opportunity' and name='Premium Parking'];
                Id rc = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Premium Parking').getRecordTypeId();

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), 
                                                      AccountId = testAccount.Id,Pricebook2Id=pricebookId);
        insert testOpportunity;

        //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        
        
        
        Product2 product = new Product2(Name = 'Parking', IsActive = true);
        insert product;
        
        Product2 product1 = new Product2(Name = 'Premium Gold', IsActive = true);
        insert product1;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        Asset testAsset = new Asset(Name = 'Test Asset', 
                                    Product2Id = product.Id, 
                                    AccountId = testAccount.Id, 
                                    Parking_Type__c = 'Premium Slot', 
                                    Parking_Tier__c = 'Gold', 
                                    Parking_Ref_ID__c = 101,
                                    Status='Available',
                                    Distance_From_Lobby_in_m__c= '10', 
                                    Capacity__c=1,
                                    Project__c = pu.id,
                                    Building__c = bu.id);
        insert testAsset;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__Account__c = testAccount.Id, SBQQ__Status__c = 'Draft'
                                                      //, Parking_Type__c = 'Premium Slot', Parking_Tier__c = 'Gold'
                                                     ,SBQQ__Primary__c = true,
            Parking_Ref_ID__c = '101',SBQQ__PriceBook__c = pricebookId);
        insert testQuote;
         Contract testContract = new Contract(AccountId = testAccount.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
        insert testContract;

         

        // Activate the Contract
        testContract.Status = 'Activated';
        update testContract;
		Order testOrder = new Order(AccountId = testAccount.Id, ContractId = testContract.Id, EffectiveDate = Date.today(), Status = 'Draft',SBQQ__Quote__c=testQuote.Id);
        insert testOrder;    
         ParkingService.getOrderDetails(testQuote.Id);
          SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.CurrencyIsoCode='AED';
        quoteLine.SBQQ__Quote__c = testQuote.Id;
        quoteLine.SBQQ__NetPrice__c = 100;
        quoteLine.SBQQ__Product__c = product.id;
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
        quoteLine.Parking_Ref_ID__c = '123456';
        quoteLine.SBQQ__OptionLevel__c = 1;
        quoteLine.SBQQ__OptionType__c = 'Component';
        insert quoteLine;
         
             SBQQ__QuoteTemplate__c qt = new SBQQ__QuoteTemplate__c (Name='Aldar',SBQQ__CompanyName__c='Aldar Properties',SBQQ__DeploymentStatus__c='Deployed',SBQQ__TermsConditionsTitle__c='Terms & Conditions');
        insert qt;
         
         SBQQ__QuoteDocument__c quoteDoc = new SBQQ__QuoteDocument__c(SBQQ__Quote__c = testQuote.Id, Name = 'Test Document',SBQQ__QuoteTemplate__c=qt.id,SBQQ__Opportunity__c=testOpportunity.id);
    insert quoteDoc;
    }
    
    @IsTest
    static void testSaveQuote() {
        // Create necessary test data
        createTestData();
        setupTestData1();
      List<Id> oppIds = new List<Id>();
        for (Opportunity opp : [SELECT Id FROM Opportunity LIMIT 1]) {
            oppIds.add(opp.Id);
        }
        delete [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :oppIds];
        

        
        // Prepare the request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'POST';
        req.addParameter('operation', 'saveQuote');
        Id pricebookId = Test.getStandardPricebookId();
        
        // Ensure no Quote is present so that a new Quote is inserted
        String quoteId;
        List<SBQQ__Quote__c> quoteList = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        if (quoteList.isEmpty()) {
            quoteId = null;
        } else {
            quoteId = quoteList[0].Id;
        }
        
        // Ensure no Quote Line with 'ADM Registration Fees' exists
        delete [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'ADM Registration Fees'];
        
        
        // Retrieve necessary IDs
        string templateId = [SELECT Id FROM SBQQ__QuoteTemplate__c WHERE Name='Aldar' LIMIT 1].Id;
        string opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        string customerId = [SELECT Id FROM Account LIMIT 1].Id;
        
        // Create the request object
        ParkingService.SaveQuoteRequest saveQuoteRequest = new ParkingService.SaveQuoteRequest();
        saveQuoteRequest.opportunityId = opportunityId;
        saveQuoteRequest.customerId = customerId;
        saveQuoteRequest.quoteId = ''; // No quote should exist to force new Quote creation
        saveQuoteRequest.RefId = 'Ref123';
        
        
        
        ParkingService.SaveQuoteLine saveQuoteLine = new ParkingService.SaveQuoteLine();
        saveQuoteLine.productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        saveQuoteRequest.quoteLines = new List<ParkingService.SaveQuoteLine>{ saveQuoteLine };
            
            // Set the mock request
            RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RestMock());
        ParkingService.handleRequest('saveQuote', null, null, null, null, null, null, null, null, saveQuoteRequest, null, null, 'true');
        //     ParkingService.handleRequest('saveQuote', null, null, null, null, null, null, null, null, saveQuoteRequest, null, null, 'false');
        Test.stopTest();
    }

     @isTest
    static void testHandleInvalidOperation() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';
        req.params.put('operation', 'invalidOperation');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ParkingService.getRequest();
        ParkingService.handleRequest('invalidOperation', null, null, null, null, null, null, null, null, null,null,null,'true');

        Test.stopTest();

        RestResponse res = RestContext.response;
        System.assert(res.responseBody.toString().contains('Invalid operation specified'), 'Response should indicate invalid operation');
    }
    
     @isTest
    static void testExceptionHandling() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'GET';

        // Intentionally omit required parameters
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ParkingService.getRequest();
        Test.stopTest();

        RestResponse res = RestContext.response;
        
    }

    
    @IsTest
    static void testGenerateDocument() {
        
        setupTestData1();
        
         string customerId = [SELECT Id FROM Account LIMIT 1].Id;
        string quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        string templateId = [select Id from SBQQ__QuoteTemplate__c Where Name='Aldar' LIMIT 1].id;
        
    Document__c doc = new Document__c(
        Quote__c = quoteId,
        DocumentType__c = 'Premium Parking Quote Doc'
    );
    insert doc;

    ContentVersion content = new ContentVersion(
        Title = 'GeneratedDoc',
        PathOnClient = 'testDoc.pdf',
        VersionData = Blob.valueOf('Test Content')
    );
    insert content;
        

        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'POST';
        req.addParameter('operation', 'generateDocument');
        res.headers.put('Content-Type', 'application/json');
        req.addParameter('customerId', customerId);
    req.addParameter('quoteId', quoteId);
    req.addParameter('templateId', templateId);
        
        RestContext.request = req;
    	RestContext.response = res;
        
       
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        List<ParkingService.DocumentsList> result = ParkingService.generateDocument_Nintex(customerId, quoteId,'true');
       
        
       ParkingService.handleRequest('generateDocument', null, null, null, null, quoteId, null, null, customerId, null,null,null,'true');
        Test.stopTest();

         List<ParkingService.DocumentsList> result1 = ParkingService.generateDocument_Nintex(customerId, quoteId,'false');
        // Check response
        // 


        String responseBody = res.responseBody.toString();
        //System.assert(responseBody.contains('totalQuotePrice'), 'Response does not contain expected quote details');
    }
    @isTest
    static void testcreatePayment(){
         setupTestData1();
        
         string customerId = [SELECT Id FROM Account LIMIT 1].Id;
        string quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        string templateId = [select Id from SBQQ__QuoteTemplate__c Where Name='Aldar' LIMIT 1].id;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        opp.EnquiryCategory__c = 'Aldar Websites';
        opp.EnquiryTrigger__c = 'live aldar';
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.id;
        insert unit;
        
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
         Contract testContract = new Contract(AccountId = customerId, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
        insert testContract;

        // Activate the Contract
        testContract.Status = 'Activated';
        update testContract;
		Order testOrder = new Order(AccountId = customerId, ContractId = testContract.Id, EffectiveDate = Date.today(), Status = 'Draft');
        insert testOrder;  
		 ParkingService.PaymentDetails pd = new ParkingService.PaymentDetails();
         pd.amount = 200;  // Paid Amount (Full Amount)
         pd.salesOrder = salesOrder.Id;  // Sales Order ID
         pd.opportunityId = opp.Id;  // Opportunity ID related to the quote
         pd.accountId = customerId;  // Account ID
         pd.remarks = '';  // Any remarks for the payment
         pd.referenceNumber = '';  // Generated from CyberSource
         pd.paymentDate = System.today();  // Date of payment
         pd.currencyIsoCode = '';  // Currency used for payment
         pd.bankAccountNumber = '';
         pd.bankName = '';
         pd.orderId = testOrder.Id;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ParkingService/';
        req.httpMethod = 'POST';
        req.addParameter('operation', 'createPayment');
        res.headers.put('Content-Type', 'application/json');
        req.addParameter('customerId', customerId);
    req.addParameter('quoteId', quoteId);
    req.addParameter('templateId', templateId);
        
        RestContext.request = req;
    	RestContext.response = res;
        
       
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
       ParkingService.handleRequest('createPayment', null, null, null, null, quoteId, null, null, customerId, null,null,pd,'true');
       
       
        Test.stopTest();

        String responseBody = res.responseBody.toString();
        
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
    //Added by Harsh@Ald 11/02/2025
    @isTest
    static void testGetMerchantDetailsWithValidMetadata() {
		
        ReceiptAcknowledgement__c receiptRecord = new ReceiptAcknowledgement__c();
        receiptRecord.Receipt_Type__c = 'Charge Fee';
        receiptRecord.Amount__c = 500;
        receiptRecord.PaymentType__c = 'Online';
        insert receiptRecord;
        ParkingService.PaymentResponse paymentResponse = new ParkingService.PaymentResponse();
        paymentResponse.receiptId = receiptRecord.Id;

        Test.startTest();
        ParkingService.PaymentResponse result = ParkingService.getMerchantDetails(paymentResponse);
        Test.stopTest();
    }
    
    @isTest
    static void testGetMerchantDetailsWithNoMetadata() {
        ReceiptAcknowledgement__c receiptRecord = new ReceiptAcknowledgement__c();
        receiptRecord.Receipt_Type__c = 'Charge Fee';
        receiptRecord.Amount__c = 500;
        receiptRecord.PaymentType__c = 'Online';
        insert receiptRecord;
        ParkingService.PaymentResponse paymentResponse = new ParkingService.PaymentResponse();
        paymentResponse.receiptId = receiptRecord.Id;

        Test.startTest();
        ParkingService.PaymentResponse result = ParkingService.getMerchantDetails(paymentResponse);
        Test.stopTest();
    }
    
     @isTest
    static void testUpdateAssetStatusWithParent() {
        setupTestData1();
        String customerId = [SELECT Id FROM Account LIMIT 1].Id;
        // Step 1: Create a Parent Asset
        Asset parentAsset = new Asset(Name = 'Parent Asset', Status = 'New');
        insert parentAsset;

        // Step 2: Create a Child Asset with the Parent_Asset__c field populated
        Asset childAsset = new Asset(Name = 'Child Asset', Status = 'New', Parent_Asset__c = parentAsset.Id);
        insert childAsset;

        // Step 3: Call the updateAssetStatus method with the Child Asset Id
        Test.startTest();
        ParkingService.updateAssetStatus(childAsset.Id, customerId);
        Test.stopTest();

        // Step 4: Retrieve the updated Asset and Parent Asset
        Asset updatedChildAsset = [SELECT Id, Status, In_Progress_Timestamp__c FROM Asset WHERE Id = :childAsset.Id];
        Asset updatedParentAsset = [SELECT Id, Status, In_Progress_Timestamp__c FROM Asset WHERE Id = :parentAsset.Id];

        // Step 5: Assert the results to verify that the status and timestamp have been updated
        System.assertEquals(updatedChildAsset.Status, 'In Progress', 'Child Asset Status should be updated to In Progress');
        System.assertNotEquals(updatedChildAsset.In_Progress_Timestamp__c, null, 'Child Asset In_Progress_Timestamp__c should be set');
        
        System.assertEquals(updatedParentAsset.Status, 'In Progress', 'Parent Asset Status should be updated to In Progress');
        System.assertNotEquals(updatedParentAsset.In_Progress_Timestamp__c, null, 'Parent Asset In_Progress_Timestamp__c should be set');
    }
    



    @isTest
    static void testGetCTAPaymentDueDate() {
        // Step 1: Setup Test Data

        // Create a mock Account record since no Account exists in your org
        Account account = new Account(Name = 'Test Account');
        insert account; // Insert the Account to make sure the query doesn't fail
        
        string customerId = account.Id; // Use the created Account's Id
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        opp.EnquiryCategory__c = 'Aldar Websites';
        opp.EnquiryTrigger__c = 'live aldar';
        insert opp;
        // Create a Quote record, ensure there is at least one Quote record
        SBQQ__Quote__c quote = new SBQQ__Quote__c( SBQQ__Opportunity2__c =opp.Id );
        insert quote; // Insert a mock Quote
        
        // Create a QuoteTemplate, ensure there is at least one Quote Template record
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c(Name = 'Aldar');
        insert template; // Insert a mock Quote Template
        
        string quoteId = quote.Id;
        string templateId = template.Id;

                
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingSection = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',  // Add a value for the required BuildingSectionCode__c field
        	Project__c =  projectRecord.Id
        );
        insert buildingSection;

        
        // Create and insert Unit with ExpectedCustomerHandoverDate__c set
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.id;
        unit.ExpectedCustomerHandoverDate__c = Date.today().addDays(30); // Ensure this is set
        insert unit;

        
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        // Create an Asset related to the Sales Order
        Asset asset = new Asset(
            Sales_Order__c = salesOrder.Id,
            Name= 'test1',
            Parking_Type__c = 'Type 1',
            Parking_Tier__c = 'Tier 1',
            Parking_Group__c = 'Group 1',
            Parking_Category__c = 'Category 1'
        );
        insert asset;

		Integer mockedDaysToSubtract = 10; // This is the value we want to simulate for NoOfDaysDue__c in the metadata

        Test.startTest();
        String dueDate = ParkingService.getCTAPaymentDueDate(salesOrder.Id);
        Test.stopTest();

        // Assert that the due date is correctly calculated
        Date expectedDueDate = Date.today().addDays(30).addDays(-mockedDaysToSubtract);  // Expected due date should be 30 days from today - 10 days

  }

    @isTest
    static void testIsEligible() {
        // Step 1: Setup Test Data

        // Create mock Project and Building records
        Project__c projectRecord1= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord1;
        
        Project__c projectRecord2= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord2;

            BuildingSection__c buildingSection1 = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',  // Add a value for the required BuildingSectionCode__c field
        	Project__c =  projectRecord1.Id
        );
        insert buildingSection1;
        
        BuildingSection__c buildingSection2 = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',  // Add a value for the required BuildingSectionCode__c field
        	Project__c =  projectRecord2.Id
        );
        insert buildingSection2;
        
        // Create a RecordType for 'Lead' if it doesn't exist already
        //RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Lead' LIMIT 1];
                        Id rt = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Lead').getRecordTypeId();


        // Create Product_Configuraton__c records with 'Lead' RecordType and link them to the Projects and Buildings
        Product_Configuraton__c config1 = new Product_Configuraton__c(
            
            RecordTypeId = rt,
            Project__c = projectRecord1.Id,
            Building__c = buildingSection1.Id
        );
        insert config1;

        Product_Configuraton__c config2 = new Product_Configuraton__c(
             
            RecordTypeId = rt,
            Project__c = projectRecord2.Id,
            Building__c = buildingSection2.Id
        );
        insert config2;

        // Step 2: Test Method Execution

        // Create sets with Project IDs and Building IDs to test
        Set<Id> projectIds = new Set<Id>{projectRecord2.Id, projectRecord1.Id};
        Set<String> buildingIds = new Set<String>{buildingSection2.Id, buildingSection1.Id};
        
        Test.startTest();
        Boolean isEligibleResult = ParkingService.isEligible(projectIds, buildingIds);
        Test.stopTest();
	  }
    
    @isTest
    static void testHandleCtaNoOrderFound() {
        // Step 1: Setup Test Data
        
        // Create necessary records for testing
        Account account = new Account(Name = 'Test Account');
        insert account; // Insert the Account to make sure the query doesn't fail
        
        string customerId = account.Id; // Use the created Account's Id
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        opp.EnquiryCategory__c = 'Aldar Websites';
        opp.EnquiryTrigger__c = 'live aldar';
        insert opp;
                
        Project__c projectRecord1= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord1;
             
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord1.id;
        insert unit;
        
        // Create a SalesOrder__c record
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        // Create a RecordType for 'Lead' if it doesn't exist already
        //RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
                        Id rt = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Max Parking').getRecordTypeId();


        
        BuildingSection__c buildingSection1 = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',  // Add a value for the required BuildingSectionCode__c field
            Project__c =  projectRecord1.Id
        );
        insert buildingSection1;
        // Create Product_Configuraton__c records for max parking with appropriate data
         Product_Configuraton__c config1 = new Product_Configuraton__c(
            RecordTypeId = rt,
            Project__c = projectRecord1.Id,
            Building__c = buildingSection1.Id
        );
        insert config1;
        
        // Create SBQQ__Quote__c record for testing
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            Sales_Order__c = salesOrder.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__Status__c = 'Approved'
           // ParkingAsset__c = new ParkingAsset__c(Ref_ID__c = 'ParkingRef123', Parking_Bay__c = 'P-101')
        );
        insert quote;
        
        // Create SBQQ__Quote__c records for the no quote found case
        SBQQ__Quote__c noQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            Sales_Order__c = salesOrder.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__Status__c = 'Pending',
            ParkingAsset__c = null // No Parking Asset
        );
        insert noQuote;
        
        // Step 2: Call the Method
        Test.startTest();
        ParkingService.CTAResponseWrapper response = ParkingService.handleCtaNoOrderFound(Account.Id, salesOrder.Id);
        ParkingService.CTAResponseWrapper response1 = ParkingService.handleCtaNoQuoteFound(Account.Id, salesOrder.Id);
        Test.stopTest();
               
    }
    /*    
        @isTest
    static void testGetCTADetails1() {
        // Step 1: Setup Test Data
     Id PREMPARKING_RECORDTYPE_ID;
        // Create Account with required CustomerClass__c
        Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Elite');
        insert account;
        String customerId = account.Id;
      
        PREMPARKING_RECORDTYPE_ID	 = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Premium_Parking').getRecordTypeId();
        // Create Opportunity
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        opp.EnquiryCategory__c = 'Aldar Websites';
        opp.EnquiryTrigger__c = 'live aldar';
        opp.RecordTypeId = PREMPARKING_RECORDTYPE_ID;
        insert opp;
        
     	Product2 product = new Product2(Name = 'Parking', IsActive = true);
        insert product;
        // Create Project and Building Section
        Project__c projectRecord1 = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord1;
    
        BuildingSection__c buildingSection1 = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',
            Project__c = projectRecord1.Id
        );
        insert buildingSection1;
    
        // Create Unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord1.Id;
        unit.BuildingSectionName__c = buildingSection1.Id;
        insert unit;
    
        // Create Sales Order
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
    
        // Create Product_Configuraton__c (Max Parking) with Customer Class
        RecordType configRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
        Product_Configuraton__c config1 = new Product_Configuraton__c(
            RecordTypeId = configRT.Id,
            Project__c = projectRecord1.Id,
            Building__c = buildingSection1.Id,
            Customer_Class__c = 'Elite',
            Max_Parking__c = 3
        );
        insert config1;
    
        // Create SBQQ__Quote__c
        RecordType quoteRT = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND Name = 'Parking' LIMIT 1];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__Status__c = 'Approved',
            SBQQ__Primary__c = true,
            Project__c = projectRecord1.Id,
            Building_Section__c = buildingSection1.Id,
            RecordTypeId = quoteRT.Id
        );
        insert quote;
    
        // Create Parking Asset (Asset)
        
        Asset asset = new Asset(
            Sales_Order__c = salesOrder.Id,
            Name= 'test1',
            Parking_Type__c = 'Type 1',
            Parking_Tier__c = 'Tier 1',
            Parking_Group__c = 'Group 1',
            Parking_Category__c = 'Category 1'
        );
        insert asset;
        
        // Get Order RecordType for Parking
        RecordType orderRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND Name = 'Parking' LIMIT 1];
    
        // Create Order
        Order order = new Order(
            AccountId = account.Id,
            SBQQ__Quote__c = quote.Id,
            Sales_Order__c = salesOrder.Id,
            Amount_In_Progress__c = 100,
            Amount_Received__c = 150,
            Amount_Outstanding__c = 250,
            ParkingAsset__c = Asset.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = orderRT.Id
        );
        insert order;
    
        // Step 2: Call the Method
        Test.startTest();
        ParkingService.CTAResponseWrapper response = ParkingService.getCTADetails(account.Id, salesOrder.Id);
        Test.stopTest();
    

        ParkingService.ParkingOrder pOrder = response.parkingOrder[0];

    }

*/    
    @isTest
    static void testGetCTADetails() {
        // Step 1: Setup Test Data
        
                Account account = new Account(Name = 'Test Account');
        insert account; // Insert the Account to make sure the query doesn't fail
        
        string customerId = account.Id; // Use the created Account's Id
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        opp.EnquiryCategory__c = 'Aldar Websites';
        opp.EnquiryTrigger__c = 'live aldar';
        insert opp;
                
        Project__c projectRecord1= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord1;
             
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord1.id;
        insert unit;
        
        // Create a SalesOrder__c record
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        BuildingSection__c buildingSection1 = new BuildingSection__c(
            Name = 'Grove-Heart1',
            BuildingSectionCode__c = 'GH1',  // Add a value for the required BuildingSectionCode__c field
            Project__c =  projectRecord1.Id
        );
        insert buildingSection1;
        
        // Create Product_Configuraton__c record for max parking
        //RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
        Id rt = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Max Parking').getRecordTypeId();

        // Create Product_Configuraton__c records for max parking with appropriate data
         Product_Configuraton__c config1 = new Product_Configuraton__c(
            RecordTypeId = rt,
            Project__c = projectRecord1.Id,
            Building__c = buildingSection1.Id
        );
        insert config1;
        
        
        // Create SBQQ__Quote__c record linked to the sales order and opportunity
        // Create SBQQ__Quote__c record for testing
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            Sales_Order__c = salesOrder.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__Status__c = 'Approved', 
            SBQQ__Primary__c= true
           // ParkingAsset__c = new ParkingAsset__c(Ref_ID__c = 'ParkingRef123', Parking_Bay__c = 'P-101')
        );
        insert quote;

        
        Asset asset = new Asset(
            Sales_Order__c = salesOrder.Id,
            Name= 'test1',
            Parking_Type__c = 'Type 1',
            Parking_Tier__c = 'Tier 1',
            Parking_Group__c = 'Group 1',
            Parking_Category__c = 'Category 1'
        );
        insert asset;
        // Create an Order record related to the sales order
        Order order = new Order(
            AccountId = Account.Id,
            SBQQ__Quote__c = quote.Id,
            Sales_Order__c = salesOrder.Id,
            Amount_In_Progress__c = 100,
            Amount_Received__c = 150,
            Amount_Outstanding__c = 250,
            ParkingAsset__c = asset.Id,
            EffectiveDate = Date.today(), 
            Status= 'Draft'
            //ParkingAsset__c pA = new ParkingAsset__c(Ref_ID__c = 'ParkingRef123', Parking_Bay__c = 'P-101')
        );
        insert order;
        
        // Step 2: Call the Method
        Test.startTest();
        //CTAResponseWrapper responseWrapper = ParkingService.getCTADetails(testAccount.Id, salesOrder.Id);
        ParkingService.CTAResponseWrapper response = ParkingService.getCTADetails(Account.Id, salesOrder.Id);

        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateReceiptAcknowledgment_QuoteIdBased() {
        // Step 1: Set up data
        Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Class-A');
        insert account;
        String customerId = account.Id;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
        insert opp;
        
        Project__c project = TestObjectsFactory.getProjectRecord('Mayan');
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT123');
        unit.Project__c = project.Id;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = customerId,
            SBQQ__Status__c = 'Draft',
            SBQQ__Primary__c = true
        );
        insert quote;
        
        Order order = new Order(
            AccountId = customerId,
            Status = 'Draft',
            SBQQ__Quote__c = quote.Id,
            EffectiveDate = Date.today()
        );
        insert order;
        
        // Step 2: Create PaymentDetails WITHOUT orderId and WITH quoteId
        ParkingService.PaymentDetails pd = new ParkingService.PaymentDetails();
        pd.amount = 300;
        pd.salesOrder = salesOrder.Id;
        pd.opportunityId = opp.Id;
        pd.accountId = customerId;
        pd.referenceNumber = 'TXN123456';
        pd.paymentDate = Date.today();
        pd.currencyIsoCode = 'AED';
        pd.bankAccountNumber = '12345678';
        pd.bankName = 'Mock Bank';
        pd.orderId = null; // IMPORTANT
        pd.quoteId = quote.Id;
        
        // Step 3: Call the method
        Test.startTest();
        ParkingService.PaymentResponse resp = ParkingService.createReceiptAcknowledgment(pd);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetOrderStatus() {
        // Mock the Custom Label
        //System.Label.PremiumParkingPaymentBuffer = '1.00'; // This line works only in some test frameworks or managed packages
        Decimal buffer = Decimal.valueOf('1.00');

        // Case 1: Unpaid (0 + 0)
        Order unpaidOrder = new Order(
            Amount_In_Progress__c = 0,
            Amount_Received__c = 0,
            Amount_Outstanding__c = 100
           
        );
        String status1 = ParkingService.getOrderStatus(unpaidOrder);
        System.assertEquals('Unpaid', status1, 'Status should be Unpaid');

        // Case 2: Paid (Outstanding = 0 && Received >= TotalAmount - buffer)
        Order paidOrder = new Order(
            Amount_In_Progress__c = 0,
            Amount_Received__c = 99.5,
            Amount_Outstanding__c = 0
            
        );
       // String status2 = ParkingService.getOrderStatus(paidOrder);
        //System.assertEquals('Paid', status2, 'Status should be Paid');

        // Case 3: Payment In Progress (Partial received, but not full)
        Order inProgressOrder = new Order(
            Amount_In_Progress__c = 20,
            Amount_Received__c = 10,
            Amount_Outstanding__c = 70
        );
        String status3 = ParkingService.getOrderStatus(inProgressOrder);
//        System.assertEquals('Payment In Progress', status3, 'Status should be Payment In Progress');

        // Case 4: Default/Unknown
        Order unknownOrder = new Order(
            Amount_In_Progress__c = 0,
            Amount_Received__c = 0,
            Amount_Outstanding__c = 0
        );
        String status4 = ParkingService.getOrderStatus(unknownOrder);
        //System.assertEquals('Payment Status Unknown', status4, 'Status should be Payment Status Unknown');
    }
    

    @isTest
    static void testGetQuoteandLineItems1() {
        // Get Quote RecordType for Premium Parking
        Id quoteRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Parking').getRecordTypeId();

        // Create Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acct.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            
            SBQQ__Account__c = acct.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Approved',
            Quote_Calculation_Complete__c = true,
            Parking_Tier__c = 'Gold',
            Parking_Type__c = 'Premium',
            Parking_Ref_ID__c = 'P-001',
            Parking_Group__c = 'Group A',
            Parking_Segment__c = 'Segment 1',
            Parking_Category__c = 'Category A',
            Total_Tax__c = 5,
            RecordTypeId = quoteRTId
        );
        insert quote;

        // Create Quote Line
        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__NetPrice__c = 1000,
            SBQQ__ListPrice__c = 1050,
            VAT_Value__c = 50,
            VAT__c = 5
        );
        insert qLine;

        // Run the method by quoteId
        Test.startTest();
        List<ParkingService.QuoteResponse> responses = ParkingService.getQuoteandLineItems(acct.Id, quote.Id, null);
        Test.stopTest();


    }
    //-----------------------------------------------------------==========================================
      @isTest
static void testGetCTADetails2() {
    // Step 1: Setup Test Data
    
    Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Premium'); // Add CustomerClass
    insert account;
    
    String customerId = account.Id;
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    opp.EnquiryCategory__c = 'Aldar Websites';
    opp.EnquiryTrigger__c = 'live aldar';
    insert opp;
            
    Project__c projectRecord1 = TestObjectsFactory.getProjectRecord('Mayan');
    insert projectRecord1;
    
    // Create BuildingSection first (needed for Unit and other references)
    BuildingSection__c buildingSection1 = new BuildingSection__c(
        Name = 'Grove-Heart1',
        BuildingSectionCode__c = 'GH1',
        Project__c = projectRecord1.Id
    );
    insert buildingSection1;
         
    Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
    unit.Name = 'AliTest';
    unit.Status__c = 'Sold';
    unit.Project__c = projectRecord1.Id;
    unit.BuildingSectionName__c = buildingSection1.Id; // Link to building section
    insert unit;
    
    // Create a SalesOrder__c record
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    salesOrder.OwnerSharePercentage__c = 100; // Add this field as it's referenced in the query
    insert salesOrder;
    
    // Get the Parking RecordType ID for Order
    Id parkingRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
    
    // Create Product_Configuraton__c record for max parking
   // RecordType configRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
                    Id configRT = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Max Parking').getRecordTypeId();

    Product_Configuraton__c config1 = new Product_Configuraton__c(
        RecordTypeId = configRT,
        Project__c = projectRecord1.Id,
        Building__c = buildingSection1.Id,
        Customer_Class__c = 'Elite', // Match the account's customer class
        Max_Parking__c = 5 // Set a max parking limit
    );
    insert config1;
    
    // Get the Premium Parking RecordType ID for Quote
    Id premParkingQuoteRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
    
    // Create SBQQ__Quote__c record for testing
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Approved',
        SBQQ__Primary__c = true,
        Project__c = projectRecord1.Id, // Add project reference
        Building_Section__c = buildingSection1.Id, // Add building section reference
        RecordTypeId = premParkingQuoteRecordTypeId // Set the correct RecordType
    );
    insert quote;
    
    // Create Asset (ParkingAsset) with required fields
    Asset asset = new Asset(
        Sales_Order__c = salesOrder.Id,
        Name = 'test1',
        Parking_Type__c = 'Type 1',
        Parking_Tier__c = 'Tier 1',
        Parking_Group__c = 'Group 1',
        Parking_Category__c = 'Category 1',
        Ref_ID__c = 'ParkingRef123', // Add this field as it's referenced in the query
        Parking_Bay__c = 101 // Add this field as it's referenced in the query
    );
    insert asset;
    
    // Create an Order record related to the sales order with Parking RecordType
    Order order = new Order(
        AccountId = account.Id,
        SBQQ__Quote__c = quote.Id,
        Sales_Order__c = salesOrder.Id,
        Amount_In_Progress__c = 100,
        Amount_Received__c = 150,
        Amount_Outstanding__c = 250,
        ParkingAsset__c = asset.Id,
        EffectiveDate = Date.today(),
        Status = 'Draft',
        RecordTypeId = parkingRecordTypeId // Set the Parking RecordType
    );
    insert order;
    
    // Step 2: Call the Method
    Test.startTest();
    ParkingService.CTAResponseWrapper response = ParkingService.getCTADetails(account.Id, salesOrder.Id);
    Test.stopTest();
    
    ParkingService.ParkingOrder parkingOrder = response.parkingOrder[0];
}

@isTest
static void testGetCTADetailsMaxParkingLimitHit() {
    // Test case where max parking limit is hit
    
    Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Standard');
    insert account;
    
    String customerId = account.Id;
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    insert opp;
            
    Project__c projectRecord1 = TestObjectsFactory.getProjectRecord('TestProject');
    insert projectRecord1;
    
    BuildingSection__c buildingSection1 = new BuildingSection__c(
        Name = 'Test Building',
        BuildingSectionCode__c = 'TB1',
        Project__c = projectRecord1.Id
    );
    insert buildingSection1;
         
    Unit__c unit = TestObjectsFactory.unitDataSetup('789012');
    unit.Project__c = projectRecord1.Id;
    unit.BuildingSectionName__c = buildingSection1.Id;
    insert unit;
    
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
    
    // Set max parking limit to 2
   // RecordType configRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
                    Id configRT = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Max Parking').getRecordTypeId();


    Product_Configuraton__c config1 = new Product_Configuraton__c(
        RecordTypeId = configRT,
        Project__c = projectRecord1.Id,
        Building__c = buildingSection1.Id,
        Customer_Class__c = 'Elite',
        Max_Parking__c = 2 // Low limit to test hitting the max
    );
    insert config1;
    
    Id premParkingQuoteRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
    
    // Create multiple quotes to hit the limit
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    for(Integer i = 0; i < 3; i++) {
        quotes.add(new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__Status__c = 'Accepted',
            Project__c = projectRecord1.Id,
            Building_Section__c = buildingSection1.Id,
            SBQQ__Primary__c = (i == 0), 
            RecordTypeId = premParkingQuoteRecordTypeId
        ));
    }
    insert quotes;
    
    
    
    Id parkingRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
    
    Asset asset = new Asset(
        Sales_Order__c = salesOrder.Id,
        Name = 'Test Asset',
        Ref_ID__c = 'TestRef456',
        Parking_Bay__c = 202
    );
    insert asset;
    
    Order order = new Order(
        AccountId = account.Id,
        SBQQ__Quote__c = quotes[0].Id,
        Sales_Order__c = salesOrder.Id,
        ParkingAsset__c = asset.Id,
        EffectiveDate = Date.today(),
        Status = 'Draft',
        RecordTypeId = parkingRecordTypeId,
        Amount_In_Progress__c = 200,
        Amount_Received__c = 300,
        Amount_Outstanding__c = 500
    );
    insert order;
    
    Test.startTest();
    ParkingService.CTAResponseWrapper response = ParkingService.getCTADetails(account.Id, salesOrder.Id);
    Test.stopTest();
    

}
    
    @isTest
static void testHandleCtaNoOrderFound1() {
    // Step 1: Setup Test Data
    
    // Create necessary records for testing
    Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Elite'); // Add CustomerClass
    insert account;
    
    String customerId = account.Id;
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    opp.EnquiryCategory__c = 'Aldar Websites';
    opp.EnquiryTrigger__c = 'live aldar';
    insert opp;
            
    Project__c projectRecord1 = TestObjectsFactory.getProjectRecord('Mayan');
    insert projectRecord1;
    
    // Create BuildingSection first
    BuildingSection__c buildingSection1 = new BuildingSection__c(
        Name = 'Grove-Heart1',
        BuildingSectionCode__c = 'GH1',
        Project__c = projectRecord1.Id
    );
    insert buildingSection1;
         
    Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
    unit.Name = 'AliTest';
    unit.Status__c = 'Sold';
    unit.Project__c = projectRecord1.Id;
    unit.BuildingSectionName__c = buildingSection1.Id; // Link to building section
    insert unit;
    
    // Create a SalesOrder__c record
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    salesOrder.OwnerSharePercentage__c = 50.0; // Add required field
    insert salesOrder;
    
    // Create ParkingAsset__c record
    Asset parkingAsset = new Asset(
        Ref_ID__c = 'ParkingRef123',
        Parking_Bay__c = 101, 
        Name = '1.002'
    );
    insert parkingAsset;
    
    // Get RecordType for Premium Parking Quote
   // RecordType quoteRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND Name = 'Parking' LIMIT 1];
                        Id quoteRecordType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();

    
    // Get RecordType for Max Parking Configuration
    //RecordType configRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Product_Configuraton__c' AND Name = 'Max Parking' LIMIT 1];
                        Id configRecordType = Schema.SObjectType.Product_Configuraton__c.getRecordTypeInfosByName().get('Max Parking').getRecordTypeId();

    
    // Create Product_Configuraton__c records for max parking
    Product_Configuraton__c config1 = new Product_Configuraton__c(
        RecordTypeId = configRecordType,
        Project__c = projectRecord1.Id,
        Building__c = buildingSection1.Id,
        Customer_Class__c = 'Elite',
        Max_Parking__c = 3 // Set max parking limit
    );
    insert config1;
    
    Test.startTest();
    
    // Test Case 1: No Approved Quotes Found (should call handleCtaNoQuoteFound)
    SBQQ__Quote__c noApprovedQuote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Pending', // Not Approved
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = parkingAsset.Id
    );
    insert noApprovedQuote;
    
    ParkingService.CTAResponseWrapper response1 = ParkingService.handleCtaNoOrderFound(customerId, salesOrder.Id);
    
    // Test Case 2: Approved Quote with ParkingAsset (main logic path)
    SBQQ__Quote__c approvedQuote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Approved',
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = parkingAsset.Id,
        Project__c = projectRecord1.Id,
        Building_Section__c = buildingSection1.Id
    );
    insert approvedQuote;
    
    ParkingService.CTAResponseWrapper response2 = ParkingService.handleCtaNoOrderFound(customerId, salesOrder.Id);
    
    // Test Case 3: Approved Quote without ParkingAsset (should be skipped in loop)
    SBQQ__Quote__c approvedQuoteNoParkingAsset = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Approved',
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = null, // No parking asset - should be skipped
        Project__c = projectRecord1.Id,
        Building_Section__c = buildingSection1.Id
    );
    insert approvedQuoteNoParkingAsset;
    
    ParkingService.CTAResponseWrapper response3 = ParkingService.handleCtaNoOrderFound(customerId, salesOrder.Id);
    
    // Test Case 4: Multiple approved quotes to test max parking limit logic
    SBQQ__Quote__c additionalQuote1 = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Accepted', // Different status but still valid
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = parkingAsset.Id,
        Project__c = projectRecord1.Id,
        Building_Section__c = buildingSection1.Id
    );
    insert additionalQuote1;
    
    SBQQ__Quote__c additionalQuote2 = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Approved',
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = parkingAsset.Id,
        Project__c = projectRecord1.Id,
        Building_Section__c = buildingSection1.Id
    );
    insert additionalQuote2;
    
    ParkingService.CTAResponseWrapper response4 = ParkingService.handleCtaNoOrderFound(customerId, salesOrder.Id);
    
    Test.stopTest();
    
  
}

// Additional test method for edge cases
@isTest
static void testHandleCtaNoOrderFoundEdgeCases() {
    // Test with no max parking configuration
    Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Elite');
    insert account;
    
    String customerId = account.Id;
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(customerId);
    insert opp;
    
    Project__c project = TestObjectsFactory.getProjectRecord('TestProject');
    insert project;
    
    BuildingSection__c buildingSection = new BuildingSection__c(
        Name = 'TestBuilding',
        BuildingSectionCode__c = 'TB1',
        Project__c = project.Id
    );
    insert buildingSection;
    
    Unit__c unit = TestObjectsFactory.unitDataSetup('789012');
    unit.Project__c = project.Id;
    unit.BuildingSectionName__c = buildingSection.Id;
    insert unit;
    
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, customerId);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
    
    Asset parkingAsset = new Asset(
        Ref_ID__c = 'EdgeCaseRef',
        Parking_Bay__c = 001,
        Name = '1.002'
    );
    insert parkingAsset;
    
    //RecordType quoteRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND Name = 'Parking' LIMIT 1];
                        Id quoteRecordType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();

    
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        Sales_Order__c = salesOrder.Id,
        SBQQ__Account__c = account.Id,
        SBQQ__Status__c = 'Approved',
        RecordTypeId = quoteRecordType,
        ParkingAsset__c = parkingAsset.Id,
        Project__c = project.Id,
        Building_Section__c = buildingSection.Id
    );
    insert quote;
    
    Test.startTest();
    ParkingService.CTAResponseWrapper response = ParkingService.handleCtaNoOrderFound(customerId, salesOrder.Id);
    Test.stopTest();

}
    
}