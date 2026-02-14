@isTest
public class BP_ManageSalesAppointmentsTest {
 
    @testSetup
    static void setupTestData() {


        Account acct = TestObjectsFactory.getPersonAccountRecord();
        acct.FastTrackedAccount__c = true;
        acct.FasttrackCompletionDate__c = System.today();
        insert acct;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;


        Lead leadRec = TestObjectsFactory.getLeadRecord(3, 'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Provis';
        insert leadRec;


        Communication_Preference__c cpFastTrack = new Communication_Preference__c(
            Account__c = acct.Id,
            Status__c = 'Link Sent',
            Category__c = 'FastTrack',
            Active__c = true
        );
        insert cpFastTrack;

        Communication_Preference__c cpDigital = new Communication_Preference__c(
            Account__c = acct.Id,
            Status__c = 'Link Sent',
            Category__c = 'Digital SPA',
            Active__c = true
        );
        insert cpDigital;

        Communication_Preference__c cpBooking = new Communication_Preference__c(
            Account__c = acct.Id,
            Status__c = 'Link Sent',
            Category__c = 'Booking',
            Active__c = true,
            Lead__c = leadRec.Id
        );
        insert cpBooking;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Stage 2',
            CloseDate = System.today()
        );
        insert opp;


        Communication_Preference__c cpReservationStarted = new Communication_Preference__c(
            Account__c = acct.Id,
            Lead__c = leadRec.Id,
            Unit__c = unit.Id,
            Category__c = 'Booking',
            Active__c = true,
            Opportunity__c = opp.Id,
            Status__c = 'Link Sent',
            FasttrackProgress__c = 'Started'
        );
        insert cpReservationStarted;
        
        // Create CP without Opportunity to force KYC branch
        Communication_Preference__c cpNoOpp = new Communication_Preference__c(
            Account__c = acct.Id,
            Lead__c = leadRec.Id,
            Unit__c = unit.Id,
            Category__c = 'FastTrack',
            Active__c = true,
            Status__c = 'Link Sent',     // or 'Fasttrack Completed'
            Opportunity__c = null,       // IMPORTANT
            FasttrackProgress__c = 'Init'
        );
        insert cpNoOpp;


        cpFastTrack.Resend__c = true;
        cpFastTrack.Status__c = 'Fasttrack Completed';
        cpBooking.Status__c = 'Fasttrack Completed';

        Test.startTest();
        update cpFastTrack;
        update cpBooking;
        Test.stopTest();


        
        SalesOrder__c so = new SalesOrder__c(
            Opportunity__c = null,
            Account__c = acct.Id,
            Unit__c = unit.Id,
            Is_Digital_Sales__c = true,
            Status__c = 'Reserved'
        );
        insert so;
 }


    @isTest
    static void testExecute_WithAppointments() {

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        String salesRecordTypeId = Schema.SObjectType.Appointment__c
            .getRecordTypeInfosByDeveloperName()
            .get('PreSales')
            .getRecordTypeId();

        Appointment__c app = new Appointment__c(
            Broker__c = testUser.Id,
            Lead__c = lead.Id,
            Appointment_Location__c = 'Virtual',
            RecordTypeId = salesRecordTypeId,
            Date__c = System.today()
        );
        insert app;

        System.runAs(testUser) {

            RestRequest req = new RestRequest();
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/getSalesAppointments';
            req.requestBody = Blob.valueOf(
                '{"limit":"10","offset":"0","type":"Virtual","unitid":"dummy"}'
            );

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_ManageSalesAppointments.execute();
            Test.stopTest();
        }
    }


    @isTest
    static void testExecute_WithAppointments2() {

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        String salesRecordTypeId = Schema.SObjectType.Appointment__c
            .getRecordTypeInfosByDeveloperName()
            .get('PreSales')
            .getRecordTypeId();

        Appointment__c app = new Appointment__c(
            Broker__c = testUser.Id,
            Lead__c = lead.Id,
            Appointment_Location__c = 'Fahid',
            RecordTypeId = salesRecordTypeId,
            Date__c = System.today()
        );
        insert app;

        System.runAs(testUser) {

            RestRequest req = new RestRequest();
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/getSalesAppointments';
            req.requestBody = Blob.valueOf(
                '{"limit":"10","offset":"0","type":"In-Person","leadName":"broker","AppointmentId":"ABCDS"}'
            );

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_ManageSalesAppointments.execute();
            Test.stopTest();
        }
    }


    @isTest
    static void testReservationStatusBlock() {

        Account acct = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String rtId = Schema.SObjectType.Appointment__c
            .getRecordTypeInfosByDeveloperName()
            .get('PreSales')
            .getRecordTypeId();

        Appointment__c app = new Appointment__c(
            Broker__c = testUser.Id,
            Lead__c = leadRec.Id,
            Appointment_Location__c = 'Virtual',
            RecordTypeId = rtId,
            Date__c = System.today()
        );
        insert app;

        Communication_Preference__c cp = new Communication_Preference__c(
            Account__c = acct.Id,
            Lead__c = leadRec.Id,
            Unit__c = unit.Id,
            Category__c = 'FastTrack',
            Active__c = true,
            Status__c = 'Link Sent'
        );
        insert cp;

        System.runAs(testUser) {

            RestRequest req = new RestRequest();
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/getSalesAppointments';

            req.requestBody = Blob.valueOf(
                '{"limit":"10","offset":"0","type":"Virtual",' +
                '"accountId":"' + acct.Id + '",' +
                '"unitId":"' + unit.Id + '",' +
                '"leadId":"' + leadRec.Id + '",' +
                '"appointmentId":"' + app.Id + '"' +
                '}'
            );

            RestContext.request = req;
            RestContext.response = new RestResponse();

            Test.startTest();
            BP_ManageSalesAppointments.execute();
            Test.stopTest();
        }
    }
    @isTest
    static void testExceptionBlock() {
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/getSalesAppointments';
        
        // INVALID JSON → Will cause exception in your execute() method
        req.requestBody = Blob.valueOf('{invalidJson: }');
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_ManageSalesAppointments.execute();
        Test.stopTest();
        
        
    }
//Dummy Comments
    @isTest
    static void testKYCValidBranch() {
        delete [SELECT Id FROM SalesOrder__c LIMIT 1]; 
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        
        // Insert CP without opportunity so it doesn't go to "reservation started"
        Communication_Preference__c cp = new Communication_Preference__c(
            Account__c = acct.Id,
            Lead__c = leadRec.Id,
            Unit__c = unit.Id,
            Active__c = true,
            Category__c = 'FastTrack',
            Status__c = 'Link Sent',
            FasttrackProgress__c = 'Init'
        );
        insert cp;
        
        // Mocking KYC service → RETURN TRUE
        //TestObjectsFactory.checkCustomerKYCStatus.mockValue = true;
        Test.startTest();
        List<BP_ManageSalesAppointments.SalesAppointmentDetails> result = BP_ManageSalesAppointments.getSalesAllAppointments(10, 0, 'Virtual', null, leadRec.Id, acct.Id, unit.Id, 'dummy');
        Test.stopTest();
    }
}