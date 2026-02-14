/*
*Created By     : Pavithra Gajendra
*Created Date   : 30/07/2022
*Description    : Test class for SalesOfferWebService
*/
@isTest 
private class SalesOfferWebServiceTest {
    
    /*
    * Scenario 1 : Verify Booking Details
    */
    static testmethod void testSalesOffer() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        bookingdetail.offerUnitId = unitRecord.Id ; 
        bookingdetail.customerName = 'Pavithra Gajendra';
        TestObjectsFactory.initializeRestContext(null, '/query/salesofferdetails');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        SalesOfferWebService.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Send Email Offer
    */
    static testmethod void testSalesOfferEmail() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        bookingdetail.customerName = 'Pavithra Gajendra';
        bookingdetail.sendEmail = true ; 
        bookingdetail.offerUnitId = unitRecord.Id ; 
        TestObjectsFactory.initializeRestContext(null, '/query/salesofferdetails');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        SalesOfferWebService.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 3 : Verify Booking Details with excluding content
    */
    static testmethod void testSalesOfferNoException() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        bookingdetail.offerUnitId = unitRecord.Id ; 
        bookingdetail.customerName = 'Pavithra Gajendra';
        TestObjectsFactory.initializeRestContext(null, '/query/salesofferdetails');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        SalesOfferWebService.isRunningTest = true ;
        SalesOfferWebService.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Send Email Offer
    */
    static testmethod void testSalesOfferEmailNoException() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        bookingdetail.customerName = 'Pavithra Gajendra';
        bookingdetail.sendEmail = true ; 
        bookingdetail.offerUnitId = unitRecord.Id ; 
        TestObjectsFactory.initializeRestContext(null, '/query/salesofferdetails');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        SalesOfferWebService.isRunningTest = true ;
        SalesOfferWebService.doPost();
        Test.stopTest();
    }

}