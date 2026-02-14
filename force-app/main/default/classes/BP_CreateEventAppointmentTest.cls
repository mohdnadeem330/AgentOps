@isTest
public class BP_CreateEventAppointmentTest {
  
    @isTest
    static void testCreateAppointmentSuccess() {        
        // Prepare the test data
        String requestBody = '{ "appointmentLocation": "Test Location", "appointmentSlotTime": "10:00 AM", "appointmentStatus": "Booked", "appointmentId": "A12345", "broker": '+'"'+UserInfo.getUserId() +'"'+', "customerPresenceConfirmation": "Yes","appointmentDate": "2025-01-20", "email": "test@example.com", "emirates": "Dubai", "emiratesId": "EID12345", "createdAppointmentRecordId": "R12345", "locationCode": "LOC123", "nationality": "United Arab Emirates", "ownerId": "'+ Userinfo.getUserId() +'", "eventName": "test event", "residency": "Resident","slot": "Morning" }';

        // Set up the mock REST context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the method
        Test.startTest();
        BP_CreateEventAppointment.createAppointment();
        Test.stopTest();
    }
    
    @isTest
    static void testCancelAppointmentSuccess() {    
        
        Appointment__c app = new Appointment__c();
        app.Appointment_Status__c = AppointmentController.BOOKED_STATUS;
        app.AppointmentId__c ='123458';
        app.Date__c = System.Today().addDays(3);
        insert app;
        
        // Prepare the test data
        String requestBody = '{ "Id" : '+'"'+app.Id+'"'+' ,"appointmentLocation": "Test Location", "appointmentSlotTime": "10:00 AM", "appointmentStatus": "Cancelled", "appointmentId": "A12345", "broker": '+'"'+UserInfo.getUserId() +'"'+', "customerPresenceConfirmation": "Yes","appointmentDate": "2025-01-20", "email": "test@example.com", "emirates": "Dubai", "emiratesId": "EID12345", "createdAppointmentRecordId": "R12345", "locationCode": "LOC123", "nationality": "United Arab Emirates", "ownerId": "'+ Userinfo.getUserId() +'", "eventName": "test event", "residency": "Resident","slot": "Morning"}';

        // Set up the mock REST context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the method
        Test.startTest();
        BP_CreateEventAppointment.createAppointment();
        Test.stopTest();
    }

    @isTest
    static void testCreateAppointmentInvalidRequestBody() {
        // Set up the mock REST context with an empty body
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('');
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the method
        Test.startTest();
        BP_CreateEventAppointment.createAppointment();
        Test.stopTest();

        // Validate the response
        // String responseBody = RestContext.response.responseBody.toString();
    }

    @isTest
    static void testCreateAppointmentErrorHandling() {
        // Set up the mock REST context with invalid JSON
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{invalidJson}');
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the method
        Test.startTest();
        BP_CreateEventAppointment.createAppointment();
        Test.stopTest();
    }
}