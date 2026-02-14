@isTest
public class QuoteServiceTest {
    
    @testSetup
    static void setupData() {
        // Create an Account record
        Account account = new Account(Name = 'Test Account', CustomerClass__c = 'Class A');
        insert account;

        // Create Project
        Project__c project = new Project__c(
            Name = 'Project A',
            Country__c = 'United Arab Emirates',
            City__c = 'Dubai',
            BusinessUnitId__c = '000',
            ProjectCode__c = 'Haven'
        );
        insert project;

        // Create Building
        BuildingSection__c building = new BuildingSection__c(
            Name = 'Building A', 
            BuildingSectionCode__c = '12345',
            Project__c= project.Id
        );
        insert building;

        // Retrieve RecordTypeId for 'Premium Parking' on Asset
        Id premiumParkingRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Premium Parking').getRecordTypeId();

        // Create Product Configuration for Max_Parking calculation
        Product_Configuraton__c productConfig = new Product_Configuraton__c(
            Building__c = building.Id,
            Project__c = project.Id,
            Customer_Class__c = 'Elite',
            Max_Parking__c = 50
        );
        insert productConfig;

        // Create Unit
        Unit__c unit = new Unit__c(
            Name = 'Test Unit', 
            UnitType__c = 'Apartment', 
            BuildingSectionName__c = building.Id, 
            Project__c = project.Id
        );
        insert unit;

        // Create Opportunity
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opportunity;

        // Create Sales Order
        SalesOrder__c salesOrder = new SalesOrder__c(
            Account__c = account.Id,
            Status__c = 'Sold',
            Unit__c = unit.Id,
            Opportunity__c = opportunity.Id
        );
        insert salesOrder;

        // Create an Asset record for AssetCount calculation
        Asset asset = new Asset(
            Name='Asset1',
            Project__c = project.Id,
            Building__c = building.Id,
            Reserved_Account__c = account.Id,
            Sales_Order__c = salesOrder.Id,
             Ref_ID__c = 'TestRef123',
            RecordTypeId = premiumParkingRecordTypeId
        );
        insert asset;
    }
    
    static Order createTestOrderData() {
        // Project
        Project__c pu = new Project__c(
            Name = 'Yas Island',
            City__c = 'Abu Dhabi',
            BusinessUnitId__c = '111',
            ProjectCode__c = '111',
            CommunityName__c = 'Yas Island',
            Country__c = 'United Arab Emirates'
        );
        insert pu;
        
        // Building Section
        BuildingSection__c bu = new BuildingSection__c(
            Name = 'B1',
            BuildingSectionCode__c = 'B1',
            Project__c = pu.Id
        );
        insert bu;
        
        // Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Last',
            Email = 'test@test.com'
        );
        insert con;
        
        // Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        // RecordType for Opportunity
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Premium Parking' LIMIT 1];
        
        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = pricebookId
        );
        insert opp;
        
        // Products
        Product2 product1 = new Product2(Name = 'Parking', IsActive = true);
        insert product1;

        Product2 product2 = new Product2(Name = 'Premium Gold', IsActive = true);
        insert product2;
        
        // Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Asset
        Asset asset = new Asset(
            Name = 'Test Asset',
            Product2Id = product1.Id,
            AccountId = acc.Id,
            Parking_Type__c = 'Premium Slot',
            Parking_Tier__c = 'Gold',
            Parking_Ref_ID__c = 101,
            Status = 'Available',
            Distance_From_Lobby_in_m__c = '10',
            Capacity__c = 1,
            Project__c = pu.Id,
            Building__c = bu.Id
        );
        insert asset;
        
        // Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = acc.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Primary__c = true,
            Parking_Ref_ID__c = '101',
            SBQQ__PriceBook__c = pricebookId
        );
        insert quote;
        
        // Quote Line
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            CurrencyIsoCode = 'AED',
            SBQQ__Quote__c = quote.Id,
            SBQQ__NetPrice__c = 100,
            SBQQ__Product__c = product1.Id,
            SBQQ__PricebookEntryId__c = pbe.Id,
            Parking_Ref_ID__c = '101',
            SBQQ__OptionLevel__c = 1,
            SBQQ__OptionType__c = 'Component'
        );
        insert ql;
        
        Order ord = new Order(
            AccountId = acc.Id,
            SBQQ__Quote__c = quote.Id,
            Status = 'Draft',
            EffectiveDate = System.Today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        System.debug('Orderd 123 ' +ord );
        System.debug('Orderd 124 ' +ord.AccountId );


        insert ord;
        
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = ql.SBQQ__PricebookEntryId__c,
            Quantity = 1,
            UnitPrice = ql.SBQQ__NetPrice__c
        );
        insert oi;
        
        return ord;
    }
    

    @isTest
    static void testUpdateQuoteFields() {
        // Retrieve the inserted Quote record or create a new one if required
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Project__c = [SELECT Id FROM Project__c LIMIT 1].Id,
            SBQQ__Opportunity2__c=[SELECT Id FROM Opportunity LIMIT 1].Id,
            Building_Section__c = [SELECT Id FROM BuildingSection__c LIMIT 1].Id,
            SBQQ__Account__c = [SELECT Id FROM account LIMIT 1].Id,
            Sales_Order__c = [SELECT Id FROM SalesOrder__c LIMIT 1].Id
        );
        
        Test.startTest();
        insert quote;
        Test.stopTest();
        
        // Perform DML on the quote to invoke the trigger logic
        update quote;

        // Retrieve the updated Quote to verify changes
        quote = [SELECT Max_Parking__c, AssetCount__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    }
    
    /*@isTest
    static void testGenerateDocumentPlaceholders() {
        List<Order> orderList = new List<Order>();
        orderList.add(createTestOrderData());
        Test.startTest();
        //QuoteService.generateDocumentPlaceholders(orderList);
        Test.stopTest();

    }*/
    
    /*@isTest
    static void testHandleStaticDocumentUpload() {
        // Create a Quote with Parking_Type__c
       SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Project__c = [SELECT Id FROM Project__c LIMIT 1].Id,
            Building_Section__c = [SELECT Id FROM BuildingSection__c LIMIT 1].Id,
            SBQQ__Account__c = [SELECT Id FROM Account LIMIT 1].Id,
            Sales_Order__c = [SELECT Id FROM SalesOrder__c LIMIT 1].Id,
            Parking_Type__c = 'Enclosed Garage'
        );
        insert quote;
        Asset asset = [SELECT Id FROM Asset WHERE Project__c = :quote.Project__c LIMIT 1];

        // Create a Document__c linked to the Quote
        Document__c doc = new Document__c(
            Quote__c = quote.Id,
            DocumentType__c = 'Premium Parking Quote Doc'
        );
        insert doc;
        
        // Call the method directly
        Test.startTest();
        QuoteService.handleStaticDocumentUpload(new List<Document__c>{doc});
        Test.stopTest();
        
        // Verify the document status was updated
        doc = [SELECT Status__c FROM Document__c WHERE Id = :doc.Id];
    }*/

    /*@isTest
    static void testGetStaticResourceFile() {
        Test.startTest();
        Blob result;
        
        try {
            result = QuoteService.getStaticResourceFile('PremPark_EnclosedGarageDoc');
            System.assertNotEquals(null, result, 'Static resource should be retrieved');
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
            System.assert(false, 'Static resource not found or method visibility issue.');
        }
        
        Test.stopTest();
    }*/
    
    @IsTest
static void testPrepareMethodsCoverage() {

    /* =========================
       SETUP DATA
    ========================== */
    Account acc = new Account(
        Name = 'Acc',
        CustomerClass__c = 'Elite'
    );
    insert acc;

    Project__c project = new Project__c(
        Name = 'Proj',
        Country__c = 'United Arab Emirates',
        City__c = 'Dubai',
        BusinessUnitId__c = '001',
        ProjectCode__c = 'P01'
    );
    insert project;

    BuildingSection__c building = new BuildingSection__c(
        Name = 'B1',
        BuildingSectionCode__c = 'B1',
        Project__c = project.Id
    );
    insert building;
    
    Unit__c ut = new unit__c(
    	Name = 'unit',
    project__c =project.id,
    BuildingSectionName__c =building.Id,
      UnitType__c = 'Apartment'  );
    insert ut;

    Id maxRT = Schema.SObjectType.Product_Configuraton__c
        .getRecordTypeInfosByDeveloperName()
        .get('Max_Parking')
        .getRecordTypeId();

    Product_Configuraton__c config = new Product_Configuraton__c(
        RecordTypeId = maxRT,
        Building__c = building.Id,
        Project__c = project.Id,
        Customer_Class__c = 'Elite',
        Max_Parking__c = 10
    );
    insert config;

    Opportunity opp = new Opportunity(
        Name = 'Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id
    );
    insert opp;
    Test.startTest();
    SalesOrder__c so = new SalesOrder__c(
        Account__c = acc.Id,
        Status__c = 'Sold',
        Opportunity__c = opp.Id,
        Unit__c = ut.Id
    );
    insert so;

    Id assetRT = Schema.SObjectType.Asset
        .getRecordTypeInfosByName()
        .get('Premium Parking')
        .getRecordTypeId();

    Asset asset = new Asset(
        Name = 'Parking',
        RecordTypeId = assetRT,
        Project__c = project.Id,
        Building__c = building.Id,
        Reserved_Account__c = acc.Id,
        //Sales_Order__c = so.Id,
        Ref_ID__c = 'REF-100'
    );
    insert asset;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Account__c = acc.Id,
        SBQQ__Opportunity2__c = opp.Id,
        Project__c = project.Id,
        Building_Section__c = building.Id,
        Sales_Order__c = so.Id,
        Parking_Ref_ID__c = 'REF-100',
        SBQQ__Status__c = 'Draft',
        SBQQ__Primary__c = true
    );
    insert quote;

    /* =========================
       CALL METHODS
    ========================== */
    Map<Id, String> projectMap = new Map<Id, String>{ quote.Id => project.Id };
    Map<Id, String> buildingMap = new Map<Id, String>{ quote.Id => building.Id };
    Map<Id, Id> accountMap = new Map<Id, Id>{ quote.Id => acc.Id };
    Map<Id, String> salesOrderMap = new Map<Id, String>{ quote.Id => so.Id };
    Map<Id, String> accClassMap = new Map<Id, String>{ acc.Id => 'Elite' };

    

    Map<String, Decimal> maxMap =
        QuoteService.getMaxParkingMap(buildingMap, projectMap, accClassMap);

    Map<String, Integer> assetMap =
        QuoteService.getAssetCountMap(projectMap, buildingMap, accountMap, salesOrderMap);

    List<SBQQ__Quote__c> updatedQuotes =
        QuoteService.prepareQuotesToUpdate(
            new Set<Id>{ quote.Id },
            projectMap,
            buildingMap,
            accountMap,
            salesOrderMap,
            maxMap,
            assetMap,
            accClassMap
        );

    Test.stopTest();


}

//Added by Bhumika
    @isTest
static void testGenerateDocumentPlaceholders_Minimal() {

    // Account
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Order ord = new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today()
    );
    insert ord;

    List<Order> orderList = new List<Order>{ ord };

    Test.startTest();
    QuoteService.generateDocumentPlaceholders(orderList);
    Test.stopTest();

    List<Document__c> docs = [
        SELECT Id, Order__c, DocumentType__c, Account__c
        FROM Document__c
        WHERE Order__c = :ord.Id
    ];

    System.assert(
        docs.size() > 0,
        'Document records should be created for the order'
    );

    System.assertEquals(
        ord.Id,
        docs[0].Order__c,
        'Document should be linked to Order'
    );

    System.assertEquals(
        acc.Id,
        docs[0].Account__c,
        'Document should be linked to Account'
    );
}
    
    @isTest
static void testUpdateQuoteFields_MinimalSafe() {
    Account acc = new Account(
        Name = 'Test Account',
        CustomerClass__c = 'Elite'
    );
    insert acc;

    // Project
    Project__c project = new Project__c(
        Name = 'Test Project',
        Country__c = 'United Arab Emirates',
        City__c = 'Dubai',
        BusinessUnitId__c = '001',
        ProjectCode__c = 'PRJ1'
    );
    insert project;

    // Building Section
    BuildingSection__c building = new BuildingSection__c(
        Name = 'Building A',
        BuildingSectionCode__c = 'B1',
        Project__c = project.Id
    );
    insert building;

    // Unit (required for SalesOrder__c)
    Unit__c unit = new Unit__c(
        Name = 'Unit 1',
        UnitType__c = 'Apartment',
        Project__c = project.Id,
        BuildingSectionName__c = building.Id
    );
    insert unit;

    // Opportunity (insert only – NO update)
    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id
    );
    insert opp;

    // Sales Order
    SalesOrder__c so = new SalesOrder__c(
        Account__c = acc.Id,
        Status__c = 'Sold',
        Opportunity__c = opp.Id,
        Unit__c = unit.Id
    );
    Test.startTest();
    insert so;

    // Product Configuration (Max Parking)
    Id maxRT = Schema.SObjectType.Product_Configuraton__c
        .getRecordTypeInfosByDeveloperName()
        .get('Max_Parking')
        .getRecordTypeId();

    Product_Configuraton__c config = new Product_Configuraton__c(
        RecordTypeId = maxRT,
        Building__c = building.Id,
        Project__c = project.Id,
        Customer_Class__c = 'Elite',
        Max_Parking__c = 5
    );
    insert config;

    // Asset (Premium Parking)
    Id assetRT = Schema.SObjectType.Asset
        .getRecordTypeInfosByName()
        .get('Premium Parking')
        .getRecordTypeId();

    Asset asset = new Asset(
        Name = 'Parking Asset',
        RecordTypeId = assetRT,
        Project__c = project.Id,
        Building__c = building.Id,
        Reserved_Account__c = acc.Id,
        Sales_Order__c = so.Id,
        Ref_ID__c = 'REF-1'
    );
    insert asset;

    // Quote
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Account__c = acc.Id,
        SBQQ__Opportunity2__c = opp.Id,
        Project__c = project.Id,
        Building_Section__c = building.Id,
        Sales_Order__c = so.Id,
        Parking_Ref_ID__c = 'REF-1',
        SBQQ__Status__c = 'Draft',
        SBQQ__Primary__c = true
    );
    insert quote;

    
    QuoteService.updateQuoteFields(
        new List<SBQQ__Quote__c>{ quote }
    );
    Test.stopTest();

    
    SBQQ__Quote__c updatedQuote = [
        SELECT Max_Parking__c, AssetCount__c, ParkingAsset__c
        FROM SBQQ__Quote__c
        WHERE Id = :quote.Id
    ];

    System.assertEquals(
        5,
        updatedQuote.Max_Parking__c,
        'Max Parking should be populated'
    );

    System.assertEquals(
        1,
        updatedQuote.AssetCount__c,
        'Asset count should be populated'
    );

    System.assertNotEquals(
        null,
        updatedQuote.ParkingAsset__c,
        'Parking Asset should be linked'
    );
}

}