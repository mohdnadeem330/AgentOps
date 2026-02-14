/*
*Created By     : Hardik Vitthani
*Description    : Test class for ShipmentRequestTriggerHandler
*/
@isTest
public class ShipmentRequestTriggerHandlerTest {
    @isTest
    public static void testShipmentRequestAutoCreated() {
        String customerAddress = '{"Street":"Street","City":"City","State":"State","PostalCode":"PostalCode","Country":"Country"}';
        ShipmentRequest__c shipmentRequest = getData(true, customerAddress);
    }

    @isTest
    public static void testShipmentRequest() {
        ShipmentRequest__c shipmentRequest = getData(false, '');
        
        try {
            shipmentRequest.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            shipmentRequest.AWBNumber__c = null;
            // update shipmentRequest;

            ShipmentRequestTriggerHandler shipmentRequestHandler = new ShipmentRequestTriggerHandler();
            shipmentRequestHandler.afterUpdateMethod(new List<SObject>{shipmentRequest}, new Map<Id, SObject>{}, new List<SObject>{shipmentRequest}, new Map<Id, SObject>{});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    public static ShipmentRequest__c getdata(Boolean isAutoCreated, String customerAddress) {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.CustomerAddress__c = isAutoCreated ? customerAddress : '';
        insert salesOrder;

        ShipmentRequest__c shipmentRequest = TestObjectsFactory.getShipmentRequestRecord(salesOrder.Id, acc.Id);
        shipmentRequest.AWBNumber__c = '12345678';
        shipmentRequest.IsAutoCreated__c = isAutoCreated;
        insert shipmentRequest;
        
        return shipmentRequest;
    }
}