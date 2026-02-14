/*
*Created By     : Hardik Vitthani
*Description    : Test class for ShipmentRequestCalloutHelper
*/
@isTest
public class ShipmentRequestCalloutHelperTest {
    @isTest
    public static void testShipmentRequestCalloutFutureCallout() {
        ShipmentRequest__c shipmentRequest = getData();

        try {
            ShipmentRequestCalloutHelper.PrepareDataForCallout(new List<Id>{shipmentRequest.Id}, true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testShipmentRequestCallout() {
        ShipmentRequest__c shipmentRequest = getData();

        try {
            ShipmentRequestCalloutHelper.PrepareDataForCallout(new List<Id>{shipmentRequest.Id}, false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testTrackingCallout() {
        ShipmentRequest__c shipmentRequest = getData();

        try {
            ShipmentRequestCalloutHelper.TrackingCallout(shipmentRequest.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    public static ShipmentRequest__c getdata() {
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

        ShipmentRequest__c shipmentRequest = TestObjectsFactory.getShipmentRequestRecord(salesOrder.Id, acc.Id);
        shipmentRequest.AWBNumber__c = '12345678';
        insert shipmentRequest;
        
        return shipmentRequest;
    }
}