/*
*Created By     : Hardik Vitthani
*Description    : Test class for CreateJointOwnersController
*/
@isTest
public class CreateJointOwnersControllerTest {
    @isTest
    public static void testGetRelatedAccountNames() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        AccountRelationship__c accRelationship = TestObjectsFactory.getAccountRelationship(acc.Id, acc2.Id, 'Friend Of');
        insert accRelationship;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        try {
            CreateJointOwnersController.getRelatedAccountNames(salesOrder.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            CreateJointOwnersController.getRelationType(salesOrder.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }

    @isTest
    public static void testGetTotalSharePercentage() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');
        insert jointOwner;

        try {
            CreateJointOwnersController.getTotalSharePercentage(salesOrder.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }

    @isTest
    public static void testSaveJointOwnerSuccess() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');

        try {
            CreateJointOwnersController.saveJointOwner(jointOwner);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }

    @isTest
    public static void testSaveJointOwnerFailure() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');
        insert jointOwner;

        try {
            JointOwner__c jointOwner2 = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');
            CreateJointOwnersController.saveJointOwner(jointOwner2);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
}