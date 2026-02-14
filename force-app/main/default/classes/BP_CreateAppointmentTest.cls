@isTest
public class BP_CreateAppointmentTest {

    @isTest
    static void testCreateAppointmentSuccess() {
        String aldarExpertRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();

       // Create test Account (Agency)
        Account testAgency = new Account(
            Name = 'Test Agency',
            BillingCountry = 'United Arab Emirates',
            BillingState = 'Dubai'
        );
        insert testAgency;
        
        Project__c p = TestObjectsFactory.getProjectRecord('45223452');
        insert p;
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Provis';
        leadRec.ExistingAccount__c = testAgency.Id;
        leadRec.Date_of_Birth__c  = System.today().addMonths(-1234);
        insert leadRec;
        
        // Prepare the test data
        String requestBody = '{ "appointmentLocation": "Test Location", "appointmentSlotTime": "10:00 AM", "appointmentStatus": "Scheduled", "appointmentId": "A12345", "broker": '+'"'+testAgency.Id +'"'+', "customerPresenceConfirmation": "Yes","appointmentDate": "2025-01-20", "email": "test@example.com", "emirates": "Dubai", "emiratesId": "EID12345", "createdAppointmentRecordId": "R12345",  "leadId": "'+ leadRec.Id + '" , "locationCode": "LOC123", "nationality": "Test Nationality", "ownerId": "'+ Userinfo.getUserId() +'", "projectId": "'+ p.Id +'", "recordTypeId": "'+ aldarExpertRecordTypeId  +'", "residency": "UAE","slot": "Morning", "status": "Active" }';

        // Set up the mock REST context
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the method
        Test.startTest();
        BP_CreateAppointment.createAppointment();
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
        BP_CreateAppointment.createAppointment();
        Test.stopTest();

        // Validate the response
        String responseBody = RestContext.response.responseBody.toString();
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
        BP_CreateAppointment.createAppointment();
        Test.stopTest();

  }
}