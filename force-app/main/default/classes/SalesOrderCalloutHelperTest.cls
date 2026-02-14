@isTest
public class SalesOrderCalloutHelperTest {
    /*
    * Purpose : To Test Covrage of Sales Order Callout Helper
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testSalesOrderCalloutWithNewCustomer() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        SalesOrder__c salesOrder = getData(acc, false);

        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            Map<String, String> newMap = new Map<String, String>();
            newMap.put(acc.Id, '12344');
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, true, newMap);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testSalesOrderCalloutWithOldCustomer() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12345';
        insert acc;

        SalesOrder__c salesOrder = getData(acc, false);

        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testSalesOrderCalloutWithoutLineItem() {
         Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);

        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        } 
    }

    @isTest
    public static void testSalesOrderCalloutWithSalesCancellation() {
         Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        SalesOrder__c salesOrder = getData(acc, true);

        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        } 
    }

    public static SalesOrder__c getData(Account acc, Boolean isSaleCancellation) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        if (isSaleCancellation) {
            SalesOrderCancellation__c salesCancellation = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder.Id, unit.Id);
            salesCancellation.Cancellation_Status__c = 'Approved';
            insert salesCancellation;
        }

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        TestObjectsFactory.createOpportunityOfferLines(salesOrder.Id, 5);
        TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);

        return salesOrder;
    }
}