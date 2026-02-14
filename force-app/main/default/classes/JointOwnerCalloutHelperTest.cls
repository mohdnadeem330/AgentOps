@isTest
public with sharing class JointOwnerCalloutHelperTest {
    /*
    * Purpose : To Test Covrage of Joint Owner Callout Helper
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testJointOwnerCalloutWithNewCustomer() {
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;

        JointOwner__c jointOwner = getData(newAcc, false, '');

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            Map<String, String> newMap = new Map<String, String>();
            newMap.put(newAcc.Id, '12344');
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, true, newMap);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testJointOwnerCalloutWithOldCustomer() {
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        newAcc.ERPID__c = '12312';
        insert newAcc;

        JointOwner__c jointOwner = getData(newAcc, false, '');

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testUpdateJointOwnerCallout() {
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        newAcc.ERPID__c = '12312';
        insert newAcc;

        JointOwner__c jointOwner = getData(newAcc, false, '36275');
        jointOwner.SharePercentage__c = 15;
        update jointOwner;

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testDeleteJointOwnerCalloutWithoutERPId() {
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        newAcc.ERPID__c = '12312';
        insert newAcc;

        JointOwner__c jointOwner = getData(newAcc, true, '');

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testDeleteJointOwnerCalloutWithERPId() {
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        newAcc.ERPID__c = '12312';
        insert newAcc;

        JointOwner__c jointOwner = getData(newAcc, true, '68543');

        List<Id> joIds = new List<Id>();
        joIds.add(jointOwner.Id);
        try {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    public static JointOwner__c getData(Account newAcc, Boolean isDelete, String jointERPID) {
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

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        jointOwner.IsDeleted__c = isDelete;
        if (String.isNotBlank(jointERPID)) {
            jointOwner.ERPID__c = jointERPID;
        }
        insert jointOwner;
        return jointOwner;
    }
}