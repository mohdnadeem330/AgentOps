@isTest
public class AssetTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create a Unit__c record
        //Unit__c unit = new Unit__c(Name = 'UNIT-001');
        //insert unit;
        
        insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        //unit.Name = 'UNIT-001';
        //update unit;
        
        // Get RecordType Ids for Asset
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Asset']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Assert required RecordTypes exist
        System.assert(recordTypeMap.containsKey('Ecss_unit'), 'RecordType Ecss_unit not found');
        System.assert(recordTypeMap.containsKey('Functional_Location'), 'RecordType Functional_Location not found');

        // Create an Asset with RecordType = Ecss_unit, linked to Unit__c
        Asset ecssAsset = new Asset(
            Name = 'ECSS Asset 1',
            RecordTypeId = recordTypeMap.get('Ecss_unit'),
            Unit__c = unit.Id
        );
        insert ecssAsset;

        // Create an Asset with RecordType = Functional_Location, SF_Unit_Code__c = unit.Name
        Asset funcLocAsset = new Asset(
            Name = 'FuncLoc Asset 1',
            RecordTypeId = recordTypeMap.get('Functional_Location')
        );
        insert funcLocAsset;
    }

    @isTest
    static void testFunctionalLocationParentUpdate() {
        // Get Unit Name
        Unit__c unit = [SELECT Id, Name FROM Unit__c LIMIT 1];

        // Get the Functional_Location Asset
        Asset funcLocAsset = [
            SELECT Id, SF_Unit_Code__c, ParentId
            FROM Asset
            WHERE RecordType.Name = 'Functional Location'
            LIMIT 1
        ];

        // Step 2: Set it back to the matching Unit Name to trigger the logic
        funcLocAsset.SF_Unit_Code__c = unit.Name;
        
        Test.startTest();
        update funcLocAsset;

        // Re-query to verify ParentId was updated
        Asset updatedAsset = [
            SELECT Id, ParentId
            FROM Asset
            WHERE Id = :funcLocAsset.Id
        ];

        // Verify ParentId points to the ECSS unit asset
        Asset expectedParent = [
            SELECT Id
            FROM Asset
            WHERE RecordType.Name = 'Ecss unit'
            LIMIT 1
        ];

        System.assertEquals(
            expectedParent.Id, updatedAsset.ParentId,
            'ParentId should be set to the ECSS Asset ID'
        );
        Test.stopTest();
    }
}