@istest
public class BookingUtilityTest {
    
    static testmethod void testLockingForReservation(){
            
        Unit__c unit = TestObjectsFactory.unitDataSetup('10101');
        insert unit;
        
		BookingUtility.lockUnit(new List<Unit__c>{unit},Constants.RESERVATION_TIMMERNAME);
    }

    static testmethod void testLockingForBooking(){
            
        Unit__c unit = TestObjectsFactory.unitDataSetup('101011');
        insert unit;
        
		BookingUtility.lockUnit(new List<Unit__c>{unit},Constants.BOOKING_TIMERNAME);
    }
}