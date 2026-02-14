@isTest
public class UpdateSalesOrderStatusQueueableTest {
    
    @testSetup
    public static void testSetupData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Reserved';
        insert salesOrder;
    }
    
    @isTest
    public static void callQueueableMethod(){
        SalesOrder__c salesOrder = [SELECT Id, Account__c, Opportunity__c FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        System.enqueueJob(new UpdateSalesOrderStatusQueueable(new Set<Id>{salesOrder.Id}));
        Test.stopTest();
    }
}