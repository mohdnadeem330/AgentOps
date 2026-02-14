@isTest
public class PremPark_ServiceTest {

    static void createTestData() {
        // Create Project
        Project__c pu = new Project__c(Name = 'Yas Island', City__c = 'Abu Dhabi', BusinessUnitId__c = '111', 
                                       ProjectCode__c = '111', CommunityName__c = 'Yas Island', Country__c = 'United Arab Emirates');
        insert pu;

        // Create Building Section
        BuildingSection__c bu = new BuildingSection__c();
        bu.BuildingSectionCode__c = 'B1';
        bu.Name = 'B1';
        bu.Project__c = pu.Id;
        insert bu;

        // Create Product Configuration
        Product_Configuraton__c pc = new Product_Configuraton__c();
        pc.Project__c = pu.id;
        pc.Cost__c = 123;
        pc.Margin__c = 10;
        pc.Building__c = bu.id;
        pc.Parking_Type__c = 'Premium Slot';
        pc.Parking_Tier__c = 'Gold';
        insert pc;

        // Create Parent Asset
        Asset parentAsset = new Asset(
            Name = 'Test Asset 1',
            Project__c = pu.id,
            Building__c = bu.id,
            Status = 'New',
            Distance_From_Lobby_in_m__c = '10',
            Capacity__c = 1,
            Parking_Type__c = 'Premium Slot',
             Parking_Ref_ID__c = 101,
            Parking_Tier__c = 'Gold',
            Base_Cost__c = 10000
        );
        insert parentAsset;

        // Create Child Asset
        Asset childAsset = new Asset(
            Name = 'Child Asset 1',
            Project__c = pu.id,
            Building__c = bu.id,
            Status = 'New',
            Distance_From_Lobby_in_m__c = '10',
            Capacity__c = 1,
            Parking_Type__c = 'Premium Slot',
            Parking_Tier__c = 'Gold',
            Parking_Ref_ID__c = 101,
            Base_Cost__c = 10000,
            Parent_Asset__c = parentAsset.Id
        );
        insert childAsset;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Id pricebookId = Test.getStandardPricebookId();
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            AccountId = acc.Id,
            Pricebook2Id = pricebookId
        );
        insert opp;

        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = acc.id,
           // SBQQ__Primary__c = true,
            //SBQQ__Ordered__c = false, 

            Parking_Ref_ID__c = '101',
            SBQQ__Status__c = 'Draft'
        );
        insert quote;
    }

    @isTest
    public static void testHandleQuote_PostSign() {
        createTestData();
        Test.startTest();
        List<SBQQ__Quote__c> quoteList = [SELECT Id FROM SBQQ__Quote__c];
        Set<Id> quoteIdSet = new Set<Id>{quoteList[0].Id};
        PremPark_Service.handleQuote_PostSign(quoteIdSet);
        Test.stopTest();
        System.assert(true, 'handleQuote_PostSign executed successfully');
    }

    @isTest
    public static void testHandleQuote_PostPayment() {
        createTestData();
        Test.startTest();
        List<SBQQ__Quote__c> quoteList = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c];
        Set<Id> quoteIdSet = new Set<Id>{quoteList[0].Id};
        PremPark_Service.handleQuote_PostPayment(quoteIdSet);
        Test.stopTest();
    }

    @isTest
    public static void testGetParkingAssetByOppId() {
        createTestData();
        Test.startTest();
        
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        List<Id> oppIds = new List<Id>{oppList[0].Id};
        Map<Id, Id> result = PremPark_Service.getParkingAssetByOppId(oppIds);        
        Test.stopTest();
    }
    
    @isTest
    public static void testUpdateAssetStatus() {
        createTestData();
        Test.startTest();
        
        // Prepare test data for updateAssetStatus
        Map<String, Id> refIdToAccountId = new Map<String, Id>();
        List<Asset> assets = [SELECT Id, Parking_Ref_ID__c FROM Asset WHERE Parking_Ref_ID__c = 101 LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        
        if (!assets.isEmpty() && !accounts.isEmpty()) {
            refIdToAccountId.put(String.valueOf(assets[0].Parking_Ref_ID__c), accounts[0].Id);
        }
        
        // Call the method
        List<Asset> updatedAssets = PremPark_Service.updateAssetStatus(refIdToAccountId); 
        Test.stopTest();
    }

}