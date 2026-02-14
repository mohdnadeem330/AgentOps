@isTest
public class CustomPathTest {
    @isTest
    static void testUpdateAccount() {
        CustomPath cp = new CustomPath();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        Case caseRec = TestObjectsFactory.getStandardCase(acc.Id, con.Id, 'Customer Management');
        caseRec.Unit__c = unitrecord.Id;
        caseRec.Type = 'Rental';
        caseRec.Status = 'Reconciliation';
        caseRec.CustomerType__c = 'Owner';
        insert caseRec;
        CustomPath.getCurrentStage(caseRec.Id,'Status');
        CustomPath.getPathStages(caseRec.Id,'Type');
        CustomPath.updateSelectedStage(caseRec.Id,'Reconciliation','Status','Test');
    }
}