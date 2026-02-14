@isTest(SeeAllData=false)
public class UnitTriggerTest {

    @isTest static void setupMethod() {

        Test.startTest();
        User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca');
        insert cca;
        System.runAs(cca) {

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;
        
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSectionRecord;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);
        unit.OwnerId = cca.Id;

       // Test.startTest();

        insert unit;

        unit.PlotArea__c = 1000;
        update unit;

        System.debug('owner '+unit.owner.name);
        }

        Test.stopTest();

    }
}