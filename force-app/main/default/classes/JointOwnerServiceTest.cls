@isTest
public with sharing class JointOwnerServiceTest {
    /*
    * Purpose : To Test Covrage of Joint Owner Service
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testJointOwnerService() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        insert jointOwner;

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            JointOwnerService.queryAllFieldsWithExtraFields(joIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}