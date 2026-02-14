@isTest
public class TransferHistoryTriggerTest {
    
    @isTest static void createTransferHistoryRecord()  {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        insert acc1;
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.DirectDebitOIC__c = '123456789';
        insert projectRecord;
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unit.Id;
        salesOrderRecord.Directdebitauthorityreferencenumber__c = '1234578987654';
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord; 
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('YASPARK');
        insert unit2;
        
        SalesOrder__c salesOrderRecord1 = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord1.Unit__c=unit2.Id;
        insert salesOrderRecord1; 
        
        TransferHistory__c transferHistory = new TransferHistory__c();
        transferHistory.SalesOrder__c = salesOrderRecord.id;
        transferHistory.FromAccount__c = acc.id;
        transferHistory.ToAccount__c = acc1.Id;
        insert transferHistory;
    }       
}