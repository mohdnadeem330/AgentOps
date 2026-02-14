@isTest
public class CustomerProfileControllerTest {
    @testSetup 
    static void setupData() {
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
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
    }
    
    @isTest 
    static void testPRMControllermethods() {
        Account accRecord = [select id from Account limit 1];
        SalesOrder__c sORecord = [select id from SalesOrder__c limit 1];
        Test.startTest();
        CustomerProfileController.getAccountSalesOrderData(accRecord.Id);
        CustomerProfileController.getInstallmentLines(sORecord.Id);
        Test.stopTest();
    }
    
}