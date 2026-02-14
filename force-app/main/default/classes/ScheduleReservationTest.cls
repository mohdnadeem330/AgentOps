/*
*Created By     : Pavithra Gajendra
*Created Date   : 29/07/2022
*Description    : Test class for Reservation cancellation when the opportunity is not approved.
*/
@isTest
private class ScheduleReservationTest {
    

    static testmethod void testReservedOpportunity() {
        
        SalesOrder__c orderDetail = TestObjectsFactory.getSalesOrderData(false,'Mayan-B2-05-05');

        Opportunity opptyRec = new Opportunity();
        opptyRec.Id = orderDetail.Opportunity__c ;
        opptyRec.ReservationApprovalStatus__c = 'Approval Pending' ;
        opptyRec.ReservationApprovalRequestTime__c = System.now().addMinutes(-7200);
        update opptyRec ;
        Test.startTest();
        ScheduleReservation reservedOppty = new ScheduleReservation ();
        database.executeBatch(reservedOppty,1);
        String timeSchedule ='0 15 * * * ?'; 
        System.schedule('Reserved Units', timeSchedule,reservedOppty);
        Test.stopTest();
    }

}