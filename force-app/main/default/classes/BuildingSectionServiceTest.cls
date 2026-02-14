@isTest(SeeAllData=false)
public class BuildingSectionServiceTest {
    
    @isTest static void setupMethod() {

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');

        BuildingSectionService buildingSection = new BuildingSectionService();
        insert projectRecord;
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);

        Test.startTest();

        insert buildingSectionRecord;
        BuildingSectionService.prepareLocationNames(projectRecord.name);
        BuildingSectionService.prepareBuildingsNames(projectRecord.id);
        BuildingSectionService.checkBuildingEligiblity(buildingSectionRecord.id);

        Test.stopTest();
        
    }
}