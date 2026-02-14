@isTest
public class DeleteJointOwnerTest {
    @isTest
    public static void testJointOwnerTriggerHandler() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;
        
        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        update jointOwner;
        DeleteJointOwner.SubmitForDelete(jointOwner.Id);
        Test.stopTest();
    }
}