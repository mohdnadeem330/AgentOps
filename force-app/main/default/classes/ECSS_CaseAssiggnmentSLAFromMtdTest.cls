@isTest
public class ECSS_CaseAssiggnmentSLAFromMtdTest {
    @testSetup
    static void createData(){
        
        insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = false,
            Is_After_Update__c = false,
            Is_After_Delete__c = false,
            Is_Before_Insert__c = false,
            Is_Before_Update__c = false,
            Is_Before_Delete__c = false
        );
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            Email = 'test.contact@example.com'
        );
        insert testContact;
        
        
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
        
        
        
        Id stdPb = Test.getStandardPricebookId();
        List<Product2> productList = new List<Product2>();
        Product2 prodApt = new Product2(Name = 'Apartment', IsActive = true);
        productList.add(prodApt);
        Product2 prodTAF = new Product2(Name = 'TAF', IsActive = true);
        productList.add(prodTAF);
        Product2 prodSecurity = new Product2(Name = 'Security Deposit', IsActive = true);
        productList.add(prodSecurity);
        
        insert productList;
        
        
        
        Pricebook2 ecssPb = new Pricebook2(Name = 'ECSS', IsActive = true);
        insert ecssPb;
        List <PricebookEntry> pbEntries = new List<PricebookEntry>();
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = stdPb,
            Product2Id   = prodApt.Id,
            UnitPrice    = 100,
            IsActive     = true,           
            CurrencyIsoCode = 'AED'
        ));
        
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = ecssPb.Id,
            //Pricebook2Id = stdPb,
            Product2Id   = prodApt.Id,
            UnitPrice    = 100,
            IsActive     = true,
            CurrencyIsoCode = 'AED'
        ));
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = stdPb,
            Product2Id   = prodTAF.Id,
            UnitPrice    = 100,
            IsActive     = true,
            CurrencyIsoCode = 'AED'
        ));
        
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = ecssPb.Id,
            //Pricebook2Id = stdPb,
            Product2Id   = prodTAF.Id,
            UnitPrice    = 100,
            IsActive     = true,
            CurrencyIsoCode = 'AED'
        ));
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = stdPb,
            Product2Id   = prodSecurity.Id,
            UnitPrice    = 100,
            IsActive     = true,
            CurrencyIsoCode = 'AED'
        ));
        
        pbEntries.add(new PricebookEntry(
            Pricebook2Id = ecssPb.Id,
            //Pricebook2Id = stdPb,
            Product2Id   = prodSecurity.Id,
            UnitPrice    = 100,
            IsActive     = true,
            CurrencyIsoCode = 'AED'
        ));
        insert pbEntries;
        Id stdPbId = Test.getStandardPricebookId();
        
        // Opportunity & Quote (Draft with ECSS pricebook)
        Opportunity opp = new Opportunity(
            Name = 'Parent Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = stdPbId,
            CurrencyIsoCode = 'AED'
            
            
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
            AccountId = testAccount.Id,
            ExternalIdentifier = 'EXT-101',
            Status = 'Available for Lease',
            ECSS_Unit_Type__c = 'Apartment',
            ECSS_Floor_Number__c = '5',
            ECSS_Number_of_Bedrooms__c = '3',
            ECSS_Number_of_Baths__c = 2,
            ECSS_View__c = 'Sea',
            ECSS_Project__c = proj.Id,
            ECSS_Zone__c = zone.Id,
            ECSS_Building_Section__c = bld.Id,
            ECSS_Unit_Usage__c = 'Residential',
            ECSS_Unit_Code__c = '1234'
        );
        insert a1;
        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        testCase.CaseCategory__c = 'Home Finance';
        testCase.CaseComments__c = 'Home Finance Parent Case';
        //caseRecord.Home_Finance_Facilitator__c = 'Huspy';
        testCase.Status = 'New';
        testCase.SubVertical__c = 'Home Finance';
        // caseRecord.Sum_of_Total_Commission_for_Aldar__c = 10000;
        testCase.ContactId = testContact.Id;
        testcase.ECSS_CompanyOptions__c = 'AlDar Properties';
        testCase.ECSS_Object_Category__c= 'Community Management/OA';
        testCase.AssetId =  a1.id;
        insert testCase;
        
        
        
        ECSS_Case_Assignment_SLA__c cSLA = TestObjectsFactory.getSiteAndObjectSLA();
        cSLA.Functional_Location__c = '1234';
        cSLA.Object_Category__c = 'Community Management/OA';
        ECSS_Case_Assignment_SLA__c cSLA2 = TestObjectsFactory.getSiteAndCategorySLA();
        ECSS_Case_Assignment_SLA__c cSLA3 = TestObjectsFactory.getCategorySLA();
        List<ECSS_Case_Assignment_SLA__c> SLAList = new List<ECSS_Case_Assignment_SLA__c>();
        SLAList.add(cSLA);
        SLAList.add(cSLA2);
        SLAList.add(cSLA3);
        insert SLAList;
        
        Group grp = TestObjectsFactory.getECSS_Group();
        insert grp;
    }
    @isTest
    public static void testOwnership(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId from Case Limit 1]);
        
        list<Asset> assets = new List<Asset>();
        for(asset asset :[SELECT id,ECSS_Unit_Code__c from Asset]){
            asset.ECSS_Unit_Code__c = '1234';
            assets.add(asset);
        }
        update assets;
        Set<Id> assetIds = new Set<Id>();
        assetIds.add(caseList[0].assetId);
        ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Owner',assetIds,caseList);
        // caseList[0].Functional_Location__c = '1234567';
        //cSLA.Object_Category__c = 'Community Management/OA';
        caseList[0].CaseCategory__c	= 'CRM';
        //caseList[0].Functional_Location__c = '1234567';
        
        caseList[0].ECSS_Object_Category__c='Community Management/OA';
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Owner',assetIds,caseList);
        
        caseList[0].CaseCategory__c ='OAM';
        caseList[0].ECSS_Object_Category__c='Community Management/OA';
        update caseList;
        List<Asset> assetList = [SELECT Id from Asset  Limit 1];
        caseList[0].AssetId = assetList[0].Id;
        assetIds.add(assetList[0].Id);
        ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Owner',assetIds,caseList);
        Test.stopTest();  
        
    }
    @isTest
    public static void testEscalation(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId from Case Limit 1]);
        list<Asset> assets = new List<Asset>();
        for(asset asset :[SELECT id,ECSS_Unit_Code__c from Asset]){
            asset.ECSS_Unit_Code__c = '1234567';
            assets.add(asset);
        }
        update assets;
        caseList[0].ECSS_LatestEscalationLevel__c = 1;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c	= 'CRM';
        caseList[0].ECSS_Object_Category__c='Community Management/OA';
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c ='OAM';
        caseList[0].ECSS_Object_Category__c='Community Management/OA';
        List<Asset> assetList = [SELECT Id from Asset  Limit 1];
        caseList[0].AssetId = assetList[0].Id;
        caseList[0].ECSS_LatestEscalationLevel__c = 2;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].ECSS_LatestEscalationLevel__c = 3;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(caseList);
        
        /*assets = new List<Asset>();
        for(asset asset :[SELECT id,ECSS_Unit_Code__c from Asset]){
            asset.ECSS_Unit_Code__c = '1234567';
            assets.add(asset);
        }
        update assets;
         
        caseList[0].ECSS_LatestEscalationLevel__c = 1;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c	= 'CRM';
        caseList[0].ECSS_Object_Category__c='CRM';
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);*/
        
        caseList[0].CaseCategory__c ='OAM';
        caseList[0].ECSS_Object_Category__c='OAM';
        List<Asset> assetList1 = [SELECT Id from Asset  Limit 1];
        caseList[0].AssetId = assetList1[0].Id;
        caseList[0].ECSS_LatestEscalationLevel__c = 2;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
       
       /* caseList[0].ECSS_LatestEscalationLevel__c = 3;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(caseList);*/
        Test.stopTest();  
        
    }
    
   /* @isTest
    public static void testEscalationGetEmails(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId from Case Limit 1]);
        list<Asset> assets = new List<Asset>();
        for(asset asset :[SELECT id,ECSS_Unit_Code__c from Asset]){
            asset.ECSS_Unit_Code__c = '1234567';
            assets.add(asset);
        }
        update assets;
        caseList[0].ECSS_LatestEscalationLevel__c = 1;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c	= 'CRM';
        caseList[0].ECSS_Object_Category__c='CRM';
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c ='OAM';
        caseList[0].ECSS_Object_Category__c='OAM';
        List<Asset> assetList = [SELECT Id from Asset  Limit 1];
        caseList[0].AssetId = assetList[0].Id;
        caseList[0].ECSS_LatestEscalationLevel__c = 2;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].ECSS_LatestEscalationLevel__c = 3;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(caseList);
        Test.stopTest();  
        
    }*/
    @isTest
    public static void testEscalationGetEmailsNegative(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId from Case Limit 1]);
        list<Asset> assets = new List<Asset>();
        for(asset asset :[SELECT id,ECSS_Unit_Code__c from Asset]){
            asset.ECSS_Unit_Code__c = '1234567';
            assets.add(asset);
        }
        update assets;
        List<ECSS_Case_Assignment_SLA__c> caseAssignments = new List<ECSS_Case_Assignment_SLA__c>();
        for(ECSS_Case_Assignment_SLA__c caseAssign : [SELECT id,Site__c from ECSS_Case_Assignment_SLA__c]){
            caseAssign.Site__c ='1234';
            caseAssignments.add(caseAssign);
            
        }
        update caseAssignments;
        caseList[0].ECSS_LatestEscalationLevel__c = 1;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c	= 'CRM';
        caseList[0].ECSS_Object_Category__c='CRM';
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].CaseCategory__c ='OAM';
        caseList[0].ECSS_Object_Category__c='OAM';
        List<Asset> assetList = [SELECT Id from Asset  Limit 1];
        caseList[0].AssetId = assetList[0].Id;
        caseList[0].ECSS_LatestEscalationLevel__c = 2;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        
        caseList[0].ECSS_LatestEscalationLevel__c = 3;
        //update caseList;
        ECSS_CaseAssiggnmentSLAFromMtd.getFirstEscalationEmail(caseList);
        ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(caseList);
        Test.stopTest();  
        
    }
    
    
    
}