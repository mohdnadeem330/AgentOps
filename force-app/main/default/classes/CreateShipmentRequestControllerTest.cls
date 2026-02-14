/*
*Created By     : Hardik Vitthani
*Description    : Test class for CreateShipmentRequestController
*/
@isTest
public with sharing class CreateShipmentRequestControllerTest {
    @isTest
    public static void testGetRelatedAccountNames() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12345';
        insert acc;

        SalesOrder__c salesOrder = getData(acc, true);

        try {
            Test.startTest();
            CreateShipmentRequestController.getRelatedAccountNames(salesOrder.Id);
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testsaveShipmentRequest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12345';
        insert acc;

        SalesOrder__c salesOrder = getData(acc, false);

        Map<String, String> countryMap = new Map<String, String>();
        countryMap.put('Street', 'Test');
        countryMap.put('City', 'Abu Dhabi');
        countryMap.put('State', 'Test');
        countryMap.put('PostalCode', '');
        countryMap.put('Country', 'United Arab Emirates');

        try {
            Test.startTest();
            CreateShipmentRequestController.saveShipmentRequest(salesOrder.Id, acc.Id, countryMap);
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    public static SalesOrder__c getData(Account acc, Boolean isCreateJointOwner) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.ERPID__c = '23456';
        salesOrder.OwnerSharePercentage__c = 1;
        insert salesOrder;

        if (isCreateJointOwner) {
            Account acc2 = TestObjectsFactory.getPersonAccountRecord();
            acc2.ERPID__c = '12346';
            insert acc2;

            JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(acc2.Id, 40, 'Friend Of');
            jointOwner.SalesOrder__c = salesOrder.Id;
            insert jointOwner;
        }

        return salesOrder;
    }
}