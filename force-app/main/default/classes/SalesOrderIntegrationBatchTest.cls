@isTest
public class SalesOrderIntegrationBatchTest {
    @isTest
    public static void integrationBatchTest() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
     
        try {
            system.debug('+++salesOrder '+salesOrder.Id);
            database.executeBatch(new SalesOrderIntegrationBatch(new set<Id>{salesOrder.Id}), 50);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
}