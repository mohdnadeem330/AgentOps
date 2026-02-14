/*
*Created By     : Hardik Vitthani
*Description    : Test class for ShipmentRequestService
*/
@isTest
public class ShipmentRequestServiceTest {
    @isTest
    public static void testShipmentRequestService() {
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
        insert shipmentRequest;

        try {
            ShipmentRequestService.queryAllFieldsWithExtraFields(new List<Id>{shipmentRequest.Id});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}