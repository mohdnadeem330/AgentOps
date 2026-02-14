@isTest
public class ECSS_ProjectCommissionHelperTest {
    
    @testSetup
    static void setupData() {
        Project__c project1 =  new Project__c(Name = 'Proj A', BusinessUnitId__c = 'BU-1', ProjectCode__c = 'P-001');
        insert project1;
        
        Project__c project2 =  new Project__c(Name = 'Proj B', BusinessUnitId__c = 'BU-2', ProjectCode__c = 'P-002');
        insert project2;
        
     
        
        Project__c proj = new Project__c(Name = 'Proj A', BusinessUnitId__c = 'BU-1', ProjectCode__c = 'P-001');
        insert proj;
        
        

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

        insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );

           Asset asset1 = new Asset(Name = 'Asset One');
        insert asset1;
        
        Asset asset2 = new Asset(Name = 'Asset Two');
        insert asset2;
        
        ECSS_ProjectCommission__c pc = new ECSS_ProjectCommission__c(
            Name = 'Valid PC',
            ECSS_Project__c = project1.Id,
            ECSS_Asset__c = asset1.Id,
            ECSS_UnitCategory__c = 'Residential'
        );
        insert pc;
    }
    
    @isTest
    static void testValidInsert() {
        Project__c project2 = [SELECT Id FROM Project__c WHERE Name = 'Proj B' LIMIT 1];
        Asset asset2 = [SELECT Id FROM Asset WHERE Name = 'Asset Two' LIMIT 1];
        
        Test.startTest();
        ECSS_ProjectCommission__c pc = new ECSS_ProjectCommission__c(
            Name = 'Valid Different Combo',
            ECSS_Project__c = project2.Id,
            ECSS_Asset__c = asset2.Id,
            ECSS_UnitCategory__c = 'Residential'
        );
        insert pc; 
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicateAssetCategory() {
        Asset asset1 = [SELECT Id FROM Asset WHERE Name = 'Asset One' LIMIT 1];
        Project__c project2 = [SELECT Id FROM Project__c WHERE Name = 'Proj B' LIMIT 1];
        
        Test.startTest();
        ECSS_ProjectCommission__c dup = new ECSS_ProjectCommission__c(
            Name = 'Dup Asset + Category',
            ECSS_Project__c = project2.Id, 
            ECSS_Asset__c = asset1.Id,
            ECSS_UnitCategory__c = 'Residential' 
        );
        try {
            insert dup; 
            System.assert(false, 'Expected DUPLICATE error on Asset + Category');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate: Asset'), 'Error should mention Asset duplicate');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicateProjectCategory() {
        Project__c project1 = [SELECT Id FROM Project__c WHERE Name = 'Proj A' LIMIT 1];
        Asset asset2 = [SELECT Id FROM Asset WHERE Name = 'Asset Two' LIMIT 1];
        
        Test.startTest();
        ECSS_ProjectCommission__c dup = new ECSS_ProjectCommission__c(
            Name = 'Dup Project + Category',
            ECSS_Project__c = project1.Id, 
            ECSS_Asset__c = asset2.Id,     
            ECSS_UnitCategory__c = 'Residential' 
        );
        try {
            insert dup; 
            System.assert(false, 'Expected DUPLICATE error on Project + Category');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate: Project'), 'Error should mention Project duplicate');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateToDuplicate() {
        Project__c project1 = [SELECT Id FROM Project__c WHERE Name = 'Proj A' LIMIT 1];
        Asset asset1 = [SELECT Id FROM Asset WHERE Name = 'Asset One' LIMIT 1];
        Asset asset2 = [SELECT Id FROM Asset WHERE Name = 'Asset Two' LIMIT 1];
        
        ECSS_ProjectCommission__c pc = new ECSS_ProjectCommission__c(
            Name = 'Temp Record',
            ECSS_Project__c = project1.Id,
            ECSS_Asset__c = asset2.Id,
            ECSS_UnitCategory__c = 'Commercial'
        );
        insert pc;
        
        Test.startTest();
        pc.ECSS_UnitCategory__c = 'Residential';
        try {
            update pc; 
            System.assert(false, 'Expected DUPLICATE error on update to Project + Category');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate: Project'), 'Error should mention Project duplicate');
        }
        Test.stopTest();
    }
}