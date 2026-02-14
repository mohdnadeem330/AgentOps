/*
*Created By     : Hardik Vitthani
*Description    : Test class for UnitServiceWithoutSharing
*/
@isTest
public class UnitServiceWithoutSharingTest {
    @isTest
    public static void testUnitServiceWithoutSharing() {
        Test.startTest();
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;
        
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSectionRecord;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);
        unit.OnlineBrokerFlag__c = true;
        insert unit;

        UnitServiceWithoutSharing.getAllProjectsBrokerPortal();
        UnitServiceWithoutSharing.getAllUnitsBrokerPortal('',false);
        UnitServiceWithoutSharing.getAllUnitsBrokerPortal(projectRecord.Id,false);
        UnitServiceWithoutSharing.getUnitsFromProjectIds(new Set<Id>{projectRecord.Id});
        UnitServiceWithoutSharing.getUnitsById(new List<Id>{unit.Id},false);
        UnitServiceWithoutSharing.getAllUnitsById(new Set<Id>{unit.Id});
		UnitServiceWithoutSharing.getAllProjectsBrokerPortalBySaleType(true);
        
        Test.stopTest();
    }
}