/* 
* SPAChecklistControllerTest
*
* Test class for SPAChecklistController
*/
@isTest
private class SPAChecklistControllerTest{
    //Create setup data
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        SPAChecklist__c spaRecord = new SPAChecklist__c();
    }
    //Test the SPAChecklist__c records
    @isTest static void testSPA() {
        SalesOrder__c salesOrderRecord =[select id from SalesOrder__c limit 1];
        List<String> categoryValues = SPAChecklistController.getmdtCategory();
        System.assertEquals(categoryValues.isEmpty(), false);
        
        list<SPAChecklist__c> spaCheckListToInsert = new list<SPAChecklist__c>();
        for(SPAChecklistItem__mdt tempRec : Utilities.getChecklist()){
            spaCheckListToInsert.add(new SPAChecklist__c(ChecklistCategory__c=tempRec.Category__c, ItemName__c=tempRec.ItemName__c , SalesOrder__c=salesOrderRecord.Id));
        
        }
        insert spaCheckListToInsert;
        
        List<SPAChecklist__c> getChecklist = SPAChecklistController.DataToDisplay(salesOrderRecord.Id);
        list<map<string,string>> inputParam = new list<map<string,string>>();
        
        getChecklist = SPAChecklistController.saveSPA(inputParam,salesOrderRecord.Id);
        
        inputParam.add(new map<string,string>{'ValidatedbySalesAdmin__c' => Constants.YES});
        inputParam.add(new map<string,string>{'ValidatedbyCMTeam__c' => Constants.YES});
        inputParam.add(new map<string,string>{'Notes__c' => 'true'});
        inputParam.add(new map<string,string>{'ChecklistCategory__c' => 'Test'});
        inputParam.add(new map<string,string>{'ItemName__c' => 'Test'});
        inputParam.add(new map<string,string>{'SalesOrder__c' => salesOrderRecord.Id});
        
        getChecklist = SPAChecklistController.saveSPA(inputParam,salesOrderRecord.Id);
        
    }
}