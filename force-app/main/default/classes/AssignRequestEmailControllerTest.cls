@isTest
private class AssignRequestEmailControllerTest {
 	@testSetup static void setupData() {
     	
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
    }
    @isTest static void emailGetterTest() {
        Unit__c unitrecord = [select id from Unit__c limit 1];
        User integrationProfile = TestObjectsFactory.getUserRecord(Constants.INTEGRATION_PROFILE, 'integrationProfile');
        integrationProfile.ManagerId= userinfo.getUserId();
        insert integrationProfile;
        System.runAs(integrationProfile){
            AssignRequestEmailController obj = new AssignRequestEmailController();
        	obj.selectedUnitsIds= new list<String>{unitrecord.Id};
            
            String managerName = obj.managerName;
            List<Unit__c> unitRecords = obj.selectedUnitsList;
        }
        
    }
}