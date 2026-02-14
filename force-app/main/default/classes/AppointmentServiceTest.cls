@isTest
public class AppointmentServiceTest {
    
    @isTest
    static void callMethods() {

        Test.startTest();
        Appointment__c appointmentRec = new Appointment__c();
        appointmentRec.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        insert appointmentRec;
        
        AppointmentService.queryAllFieldsWithExtraFields(new List<Id>{appointmentRec.Id});
        Test.stopTest();
        
    }
}