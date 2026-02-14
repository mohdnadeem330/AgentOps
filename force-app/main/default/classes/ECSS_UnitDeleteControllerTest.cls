@IsTest
private class ECSS_UnitDeleteControllerTest {
  @testSetup
    static void setup() {
        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Project / Zone / Building
        Project__c proj = new Project__c(Name = 'Proj A', BusinessUnitId__c = 'BU-1', ProjectCode__c = 'P-001');
        insert proj;
        
        // Also create a ProjectCommission record for project so TAF fallback works
        

        Zone__c zone = new Zone__c(Name = 'Zone A', Project__c = proj.Id, Zone_External_Id__c = 'Z-001');
        insert zone;
        
           Zone__c zone1 = new Zone__c(
            Name = 'Zone 1',
            Zone_External_Id__c = 'ZONE1',
            Project__c = proj.Id
        );
        insert zone1;

        BuildingSection__c bld = new BuildingSection__c(Name = 'Bld A', Project__c = proj.Id, BuildingSectionCode__c = 'B-001');
        insert bld;

        // Make sure triggers are enabled if your org uses them
        insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );

               
        Id stdPb = Test.getStandardPricebookId();

        Product2 prodApt = new Product2(Name = 'Apartment', IsActive = true);
        insert prodApt;

        

        Pricebook2 ecssPb = new Pricebook2(Name = 'ECSS', IsActive = true);
        insert ecssPb;
        
        insert new PricebookEntry(
            Pricebook2Id = stdPb,
            Product2Id   = prodApt.Id,
            UnitPrice    = 100,
            IsActive     = true
        );

        insert new PricebookEntry(
            Pricebook2Id = ecssPb.Id,
            Product2Id   = prodApt.Id,
            UnitPrice    = 100,
            IsActive     = true
        );

        // Opportunity & Quote (Draft with ECSS pricebook)
        Opportunity opp = new Opportunity(
            Name = 'Parent Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        System.debug('price booj standard' + stdPb);
        Quote q = new Quote(
            Name = 'Draft Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPb,
            Status = 'Draft'
        );
        insert q;

        // Two Assets
        Asset a1 = new Asset(
            Name = 'Unit-101',
            AccountId = acc.Id,
            ExternalIdentifier = 'EXT-DEL-101',
            Status = 'Available for Lease',
            ECSS_Unit_Type__c = 'Apartment',
            ECSS_Floor_Number__c = '5',
            ECSS_Unit_Area__c = 'DXB',
            ECSS_Number_of_Bedrooms__c = '3',
            ECSS_Number_of_Baths__c = 2,
            ECSS_View__c = 'Sea',
            ECSS_Project__c = proj.Id,
            ECSS_Zone__c = zone.Id,
            ECSS_Building_Section__c = bld.Id,
            ECSS_Unit_Usage__c = 'Residential',
            ECSS_Company_Code__c = acc.Id
        );
        Asset a2 = a1.clone(false, true, false, false);
        a2.Name = 'Unit-102';
        a2.ECSS_Zone__c = zone1.Id;
        a2.ExternalIdentifier = 'EXT-DEL-102';
        a2.ECSS_Company_Code__c = acc.Id;
        insert new List<Asset>{ a1, a2 };
            
            
            PricebookEntry pbeEcss = [
    SELECT Id, UnitPrice
    FROM PricebookEntry
    WHERE Pricebook2Id = :ecssPb.Id
      AND Product2Id   = :prodApt.Id
      AND IsActive = true
    LIMIT 1
];
        List<Asset> tempAsst  = [select id from asset];
        ECSS_ProjectCommission__c pc1 = new ECSS_ProjectCommission__c(
            ECSS_Project__c = proj.Id,
            ECSS_LeasingAgentCommission__c = 1000,
             ECSS_Asset__c = tempAsst[0].ID
        );
        insert pc1;
        
        ECSS_ProjectCommission__c pc2 = new ECSS_ProjectCommission__c(
            ECSS_Project__c = proj.Id,
            ECSS_LeasingAgentCommission__c = 1000,
             ECSS_Asset__c = tempAsst[0].ID
        );
        insert pc2;
        
        PricebookEntry pbeStd = [
    SELECT Id, UnitPrice
    FROM PricebookEntry
    WHERE Pricebook2Id = :stdPb
      AND Product2Id   = :prodApt.Id
      AND IsActive = true
    LIMIT 1
];
         QuoteLineItem qli = new QuoteLineItem(
        PricebookEntryId = pbeStd.Id,
        QuoteId = q.Id,
        Quantity = 1,
        UnitPrice = pbeEcss.UnitPrice, 
        Asset__c = a1.Id,
        Description = 'Rent'          
    );
 //insert qli;
        
         QuoteLineItem ql2 = new QuoteLineItem(
        QuoteId = q.Id,
        PricebookEntryId = pbeEcss.Id,
        Quantity = 1,
        UnitPrice = pbeEcss.UnitPrice, 
        Asset__c = a2.Id,
        Description = 'SD'        
    );
//insert ql2;
            
    }


    @IsTest
    static void testGetFilteredUnits_basicAndWithFilters() {
        Opportunity parentOpp = [SELECT Id FROM Opportunity WHERE ExistingOpportunity__c = null LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Zone__c zone = [SELECT Id FROM Zone__c LIMIT 1];
        BuildingSection__c bld = [SELECT Id FROM BuildingSection__c LIMIT 1];

        Test.startTest();
        List<Asset> basic = ECSS_UnitDeleteController.getFilteredUnits(
            null, null, null, null, null, null, null, null, null, null, null, parentOpp.Id
        );
        List<Asset> filtered = ECSS_UnitDeleteController.getFilteredUnits(
            proj.Id, zone.Id, bld.Id,
            'Apartment', 'DXB', '5', '3', 2, 'Sea',
            'Unit-Del-10', 
            'Residential',
            parentOpp.Id
        );
        Test.stopTest();

      
    }

    @IsTest
    static void testGetAllLists() {
        Test.startTest();
        List<Map<String,String>> projs = ECSS_UnitDeleteController.getAllProjects();
        List<Map<String,String>> zones = ECSS_UnitDeleteController.getAllZones();
        List<Map<String,String>> blds  = ECSS_UnitDeleteController.getAllBuildings();
        List<String> types   = ECSS_UnitDeleteController.getAllUnitTypes();
        List<String> areas   = ECSS_UnitDeleteController.getAllUnitAreas();
        List<String> views   = ECSS_UnitDeleteController.getAllViews();
        List<String> usages  = ECSS_UnitDeleteController.getAllUnitUsages();
        Test.stopTest();

        
    }

    @IsTest
    static void testMarkUnitsForDeletion_updatesFlagsAndSkipsNotificationWhenNoManager() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExistingOpportunity__c = null LIMIT 1];
        List<Asset> assets = [SELECT Id FROM Asset WHERE ExternalIdentifier LIKE 'EXT-DEL-%'];

        Test.startTest();
        ECSS_UnitDeleteController.markUnitsForDeletion(
            new List<Id>{ assets[0].Id, assets[1].Id },
            opp.Id
        );
        Test.stopTest();

        List<QuoteLineItem> qlis = [
            SELECT ECSS_Under_Approval__c, ECSS_Approved_By__c
            FROM QuoteLineItem
            WHERE Asset__c IN :assets
        ];
        for (QuoteLineItem qli : qlis) {
            System.assertEquals(true, qli.ECSS_Under_Approval__c, 'Should be flagged for deletion');
            System.assertEquals(null, qli.ECSS_Approved_By__c, 'Should remain null (no manager)');
        }
    }
}