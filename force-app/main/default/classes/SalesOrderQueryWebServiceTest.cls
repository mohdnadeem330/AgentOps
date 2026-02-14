/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for SalesOrderQueryWebService
*/
@isTest
private class SalesOrderQueryWebServiceTest {
    
    /*
    * Scenario 1 : Sales Order Query
    */
    static testmethod void testSalesOrderQuery() {
        Test.startTest();

        TestObjectsFactory.initializeRestContext(null, '/query/salesorder');
        SalesOrderQueryWebService.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Sales Order Query Filters
    */
    static testmethod void testSalesOrderQueryFilters() {
        Test.startTest();

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderData(false,'Mayan-B2-05-05');
        
        salesOrder.Status__c = 'Available';
        salesOrder.BookingDate__c = Date.today();
        salesOrder.SalesManager__c = Userinfo.getUserId();
        update salesOrder;

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('orderFromDate',String.valueOf(Date.today().addDays(-2)));
        mapFieldApiFieldValues.put('orderToDate',String.valueOf(Date.today()));

        TestObjectsFactory.initializeRestContext(null, '/query/salesorder');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(mapFieldApiFieldValues));
        SalesOrderQueryWebService.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 3 : Sales Order Query Filters for exception
    */
    static testmethod void testWrongFilters() {
        Test.startTest();

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        TestObjectsFactory.getSalesOrderData(false,'Mayan-B2-05-05');

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('Unit__c',unitRecord.Id);

        TestObjectsFactory.initializeRestContext(null, '/query/salesorder');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(mapFieldApiFieldValues));
        SalesOrderQueryWebService.doPost();
        Test.stopTest();
    }
}