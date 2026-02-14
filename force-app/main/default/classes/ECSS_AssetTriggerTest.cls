/**
* @author     Ismail Hossam Eldin
* @date       2025-07-01
* @company    Cloudzlab
* @project    Provis
* @description
*   Test class for ECSS_AssetTrigger trigger logic including duplicate handling,
*   ECSSHelper behavior, trigger bypassing, and role-specific user logic.
*/
@isTest
public class ECSS_AssetTriggerTest {
    @testSetup
    static void setupTestData() {
        Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ECSS_Company').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Company',
            ECSS_Company_External_Id__c = 'COMP123',
            ECSS_Availability__c = 'Available for Lease',
            RecordTypeId = accRecTypeId
        );
        insert acc;
        
        Project__c proj = new Project__c(
            Name = 'Project',
            ECSS_SAPExternalId__c = 'PROJ001',
            BusinessUnitId__c = 'PROJ123',
            ProjectCode__c = 'PROJ123'
        );
        insert proj;
        
        Account landlord = new Account(
            Name = 'Landlord',
            SapAccountID__c = 'LAND123'
        );
        insert landlord;
        
        BuildingSection__c bs = new BuildingSection__c(
            Name = 'BS1',
            ECSS_Building_External_Id__c = 'BS_EXT_ID',
            BuildingSectionCode__c = 'BSCODE',
            Project__c = proj.Id
        );
        insert bs;
        
        Zone__c zone = new Zone__c(
            Name = 'Zone 1',
            Zone_External_Id__c = 'ZONE1',
            Project__c = proj.Id
        );
        insert zone;
        
        Product2 p = new Product2(Name = 'UnitType1', IsActive = true);
        insert p;
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User insertUser = new User(
            Username = 'insert_user@example.com.test',
            LastName = 'InsertUser',
            Email = 'insert_user@example.com',
            Alias = 'iuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US',
            ECSS_Covering_Area__c = 'DXB'
        );
        insert insertUser;
        
        User updateUser = new User(
            Username = 'update_user@example.com.test',
            LastName = 'UpdateUser',
            Email = 'update_user@example.com',
            Alias = 'uuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US',
            ECSS_Covering_Area__c = 'AUH'
        );
        insert updateUser;
        

        
        String listingRTName = System.Label.ECSS_Listing_RT;
        String UnitRTName = System.Label.ECSS_Unit;
        
        Id listingRecordTypeId =  Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(listingRTName).getRecordTypeId();
        Id unitRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(UnitRTName).getRecordTypeId();
        
        Asset asset = new Asset(
            Name = 'Test Asset DXB',
            ECSS_Unit_Area__c = 'DXB',
            ECSS_Company_Code_External_Id__c = acc.ECSS_Company_External_Id__c,
            ECSS_Project_External_Id__c = proj.ECSS_SAPExternalId__c,
            ECSS_LandlordSAPExternalId__c = landlord.SapAccountID__c,
            ECSS_Building_Section_External_Id__c = bs.ECSS_Building_External_Id__c,
            ECSS_Zone_External_Id__c = zone.Zone_External_Id__c,
            ECSS_Owner_Email__c = insertUser.Username,
            OwnerId = insertUser.Id,
            ExternalIdentifier = 'EXT123',
            RecordTypeId = unitRecordTypeId
        );
        insert asset;
    }
    @isTest
    static void testAssetTriggerInsertAndUpdate() {
        /*insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );*/
        
        Test.startTest();
        Asset asset = [SELECT Id,ECSS_Unit_Area__c FROM Asset LIMIT 1];
        List<AssetShare> insertedShares = [
            SELECT Id, UserOrGroupId 
            FROM AssetShare 
            WHERE AssetId = :asset.Id
        ];
        
        
        asset.ECSS_Unit_Area__c = 'AUH';
        update asset;
        
        List<AssetShare> updatedShares = [
            SELECT Id, UserOrGroupId 
            FROM AssetShare 
            WHERE AssetId = :asset.Id
        ];
        //System.assertEquals(updateUser.Id, updatedShares[0].UserOrGroupId);
        
        Test.stopTest();
    }
    @isTest
    static void updateMethodTest()
    {
        Test.startTest();
        Asset asset = [SELECT Id,Name FROM Asset LIMIT 1];
        asset.Name = 'Test Update';
        update asset;
        Test.stopTest();
    }
    
    @isTest
    static void ECSS_CalculateSecurityDepositFieldsTest(){
        Asset asset = [SELECT Id,Name,ECSS_Rent_BaseLine__c,ECSS_SD__c,ECSS_SD_Amount__c,RecordTypeId FROM Asset LIMIT 1];
        
        Map<Id,Asset> oldMap = new Map<Id,Asset>();
        oldMap.put(asset.Id,asset);
        asset.ECSS_SD_Amount__c = 100;
        //asset.ECSS_Rent_BaseLine__c = 2000;
		asset.ECSS_SD__c = 100;
        
        List<Asset> newList = new List<Asset>();
        newList.add(asset);
        
        Test.startTest();
        ECSS_AssetTriggerHelper.ECSS_CalculateSecurityDepositFields(newList, oldMap);
        Test.stopTest();
    }
    @isTest
    static void ECSS_UpdateAllocationGroupFields(){
        Test.startTest();
        Asset asset = [SELECT Id,Name,ECSS_Project_Allocation_Group__c FROM Asset LIMIT 1];
        AllocationGroup__c allocationGroup = new AllocationGroup__c ();
        allocationGroup.Name = 'Test Allocation Group';
        allocationGroup.StartDate__c = Date.Today();
        allocationGroup.EndDate__c = Date.Today()+30;
        allocationGroup.ECSS_Type__c = 'Project';
        allocationGroup.AllocationGroupCode__c = 'TST123';
        insert allocationGroup;
        asset.ECSS_Project_Allocation_Group__c = allocationGroup.Id;
        asset.ECSS_Area_Allocation_Group__c = allocationGroup.Id;
        update asset;
        Test.stopTest();
    }
}