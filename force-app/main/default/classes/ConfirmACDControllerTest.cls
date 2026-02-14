/**
* ConfirmACDControllerTest
*
* Test class for ConfirmACDController
*/
@isTest
private class ConfirmACDControllerTest{
    //Creating Setup data for testing
            @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
            insert orgAcc;
            Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;
    }
    @isTest static void ACDCOnfirmationTest() {
        BuildingSection__c tempRec =[select id from BuildingSection__c limit 1];
        ConfirmACDController.updateMilestoneDetails(tempRec.id,system.today());
    }
}