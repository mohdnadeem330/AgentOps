/**
* ProjectTeamNotificationHOBatchTest
*
* Test class for ProjectTeamNotificationHOBatch
*/
@isTest
private class ProjectTeamNotificationHOBatchTest{
    //Creating Setup data for testing
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
    }
    @isTest static void testACDNotification() {
        BuildingSection__c tempeRec = [select id from BuildingSection__c limit 1];
        tempeRec.AnticipatedCompletionDate__c = System.today().addDays(Integer.valueOf(System.Label.ProjectTeamNotificationFrequencyHO.split(',')[0]));
        update tempeRec;
        Test.startTest();
        System.schedule('ProjectTeamNotificationHOBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationHOBatch() );
        Test.stopTest();
    }
    @isTest static void testACDEscNotification() {
        BuildingSection__c tempeRec = [select id from BuildingSection__c limit 1];
        tempeRec.AnticipatedCompletionDate__c = System.today().addDays(Integer.valueOf(System.Label.ProjectTeamEscalationNotificationFrequencyHO.split(',')[0]));
        update tempeRec;
        Test.startTest();
        System.schedule('ProjectTeamNotificationHOBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationHOBatch() );
        Test.stopTest();
    }
    @isTest static void testHPLetterNotification() {
        BuildingSection__c tempeRec = [select id from BuildingSection__c limit 1];
        tempeRec.AnticipatedCompletionDate__c = System.today().addDays(Integer.valueOf(System.Label.HO_HandoverPhasingNotification  .split(',')[0]));
        update tempeRec;
        Test.startTest();
        System.schedule('ProjectTeamNotificationHOBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationHOBatch() );
        Test.stopTest();
    }
    @isTest static void testHCLetterNotification() {
        BuildingSection__c tempeRec = [select id from BuildingSection__c limit 1];
        tempeRec.AnticipatedCompletionDate__c = System.today().addDays(Integer.valueOf(System.Label.HO_HCLetterNotification .split(',')[0]));
        update tempeRec;
        Test.startTest();
        System.schedule('ProjectTeamNotificationHOBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationHOBatch() );
        Test.stopTest();
    }
    
}