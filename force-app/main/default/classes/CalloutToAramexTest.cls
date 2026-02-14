/*
*Created By     : Hardik Vitthani
*Description    : Test class for CalloutToAramex
*/
@isTest
public class CalloutToAramexTest {
    @isTest
    public static void testFutureService() {
        Test.startTest();
        String responseBody = '';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToAramex.calloutFutureService('{"test":"test"}', true, Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testCreateShipmentError() {
        Test.startTest();

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
        
        String responseBody = '{"Transaction":{"Reference1":null,"Reference2":null,"Reference3":null,"Reference4":null,"Reference5":null},"Notifications":[],"HasErrors":true,"Shipments":[{"ID":"00000000000","Reference1":"' + shipmentRequest.Id + '","Reference2":null,"Reference3":null,"ForeignHAWB":null,"HasErrors":true,"Notifications":[],"ShipmentLabel":{"LabelURL":"https://www.google.com","LabelFileContents":[]},"ShipmentDetails":{"Origin":"AUH","Destination":"DXB","ChargeableWeight":{"Unit":"KG","Value":0.5},"DescriptionOfGoods":"Documents","GoodsOriginCountry":"AE","NumberOfPieces":1,"ProductGroup":"DOM","ProductType":"OND","PaymentType":"P","PaymentOptions":"ACCT","CustomsValueAmount":null,"CashOnDeliveryAmount":null,"InsuranceAmount":null,"CashAdditionalAmount":null,"CollectAmount":null,"Services":null,"OriginCity":"Abu Dhabi","DestinationCity":"Dubai"},"ShipmentAttachments":[]}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToAramex.calloutFutureService('{"test":"test"}', true, Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testCreateShipment() {
        Test.startTest();

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
        
        String responseBody = '{"Transaction":{"Reference1":null,"Reference2":null,"Reference3":null,"Reference4":null,"Reference5":null},"Notifications":[],"HasErrors":false,"Shipments":[{"ID":"00000000000","Reference1":"' + shipmentRequest.Id + '","Reference2":null,"Reference3":null,"ForeignHAWB":null,"HasErrors":false,"Notifications":[],"ShipmentLabel":{"LabelURL":"https://www.google.com","LabelFileContents":[]},"ShipmentDetails":{"Origin":"AUH","Destination":"DXB","ChargeableWeight":{"Unit":"KG","Value":0.5},"DescriptionOfGoods":"Documents","GoodsOriginCountry":"AE","NumberOfPieces":1,"ProductGroup":"DOM","ProductType":"OND","PaymentType":"P","PaymentOptions":"ACCT","CustomsValueAmount":null,"CashOnDeliveryAmount":null,"InsuranceAmount":null,"CashAdditionalAmount":null,"CollectAmount":null,"Services":null,"OriginCity":"Abu Dhabi","DestinationCity":"Dubai"},"ShipmentAttachments":[]}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToAramex.calloutFutureService('{"test":"test"}', true, Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
    

    @isTest
    public static void testTrackShipment() {
        Test.startTest();

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
        
        String responseBody = '{"Transaction":null,"Notifications":[],"HasErrors":false,"TrackingResults":[{"Key":"00000000000","Value":[{"WaybillNumber":"00000000000","UpdateCode":"SH014","UpdateDescription":"Record created.","UpdateDateTime":"/Date(1658998260000+0200)/","UpdateLocation":"Abu Dhabi, United Arab Emirates","Comments":"","ProblemCode":"","GrossWeight":"0.5","ChargeableWeight":"0.5","WeightUnit":"KG"}]}],"NonExistingWaybills":[]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToAramex.calloutFutureService('{"test":"test"}', false, Constants.ARAMEX_TRACk_SHIPMENTS_INTEGRATION);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
}