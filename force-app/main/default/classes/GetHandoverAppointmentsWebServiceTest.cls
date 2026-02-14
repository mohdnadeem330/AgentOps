@isTest
public class GetHandoverAppointmentsWebServiceTest {
    @testSetup
    static void setupTestData() {
        User testUser = TestObjectsFactory.getUserRecord('System Administrator', 'testuser');
        insert testUser;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        opHours.TimeZone = 'Asia/Dubai';
        insert opHours;
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.OperatingHoursId = opHours.Id;
        timeSlot.DayOfWeek = 'Monday';
        timeSlot.MaxAppointments = 5;
        timeSlot.StartTime = Time.newInstance(9, 0, 0, 0);
        timeSlot.EndTime = Time.newInstance(18, 0, 0, 0);
        insert timeSlot;
        
        ServiceTerritory serviceTerritoryRec = new ServiceTerritory(Name = 'Test Service Territory', OperatingHoursId = opHours.Id, IsActive = true);
        insert serviceTerritoryRec;
        
        ServiceResource serviceResource = new ServiceResource(Name = 'Test Service Resource', ResourceType = 'T', RelatedRecordId = testUser.Id, IsActive = true);
        insert serviceResource;
        
        ServiceTerritoryMember serviceTerritoryMemberrec = new ServiceTerritoryMember();
        serviceTerritoryMemberrec.ServiceTerritoryId = serviceTerritoryRec.Id;
        serviceTerritoryMemberrec.ServiceResourceId = serviceResource.Id;
        serviceTerritoryMemberrec.OperatingHoursId = opHours.Id;
        serviceTerritoryMemberrec.TerritoryType = 'P';
        serviceTerritoryMemberrec.EffectiveStartDate = Datetime.valueOf('2024-09-02 05:00:00');
        insert serviceTerritoryMemberrec;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        WorkType wt = new WorkType(Name = 'Home Orientation - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        
        WorkType wt2 = new WorkType(Name = 'Desnagging - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        
        WorkType wt3 = new WorkType(Name = 'Key Handover - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert new List<WorkType>{ wt, wt2, wt3 };
            
            Id handoverRT = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Handover').getRecordTypeId();
        ServiceAppointment rec = new ServiceAppointment();
        rec.serviceTerritoryId = serviceTerritoryRec.Id;
        rec.parentRecordId = acc.Id;
        rec.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec.additionalInformation = 'Test Additional Info';
        rec.appointmentType = 'Handover';
        rec.comments = 'Test Comments';
        rec.WorkTypeId = wt.Id;
        rec.RecordTypeId = handoverRT;
        
        ServiceAppointment rec2 = new ServiceAppointment();
        rec2.serviceTerritoryId = serviceTerritoryRec.Id;
        rec2.parentRecordId = acc.Id;
        rec2.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec2.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec2.additionalInformation = 'Test Additional Info';
        rec2.appointmentType = 'Handover';
        rec2.comments = 'Test Comments';
        rec2.WorkTypeId = wt2.Id;
        rec2.RecordTypeId = handoverRT;
        
        ServiceAppointment rec3 = new ServiceAppointment();
        rec3.serviceTerritoryId = serviceTerritoryRec.Id;
        rec3.parentRecordId = acc.Id;
        rec3.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec3.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec3.additionalInformation = 'Test Additional Info';
        rec3.appointmentType = 'Handover';
        rec3.comments = 'Test Comments';
        rec3.WorkTypeId = wt3.Id;
        rec3.RecordTypeId = handoverRT;
        insert new List<ServiceAppointment>{ rec, rec2, rec3 };
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.Name = 'Noya';
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Project__c = project.Id;
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HandoverDetails__c hoDetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                             Unit__c = unit.Id,
                                                             HandoverPhaseDate__c = system.today(),
                                                             Status__c=Constants.HO_STATUS_READY,
                                                             Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                             SalesOrder__c = salesOrder.Id,
                                                             isRTOHandover__c =  false,
                                                             UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                             TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                             HandoverAgent__c = UserInfo.getUserId(),
                                                             Home_Orientation_Appointment__c = rec.Id,
                                                             Desnagging_Appointment__c = rec2.Id,
                                                             Key_Handover_Appointment__c = rec.Id);                                        
        insert hoDetail;
        
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;
    }
    
    @isTest
    static void testValidRequest() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = 'Home Orientation';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testValidRequestForDesnagging() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = 'DeSnagging';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testValidRequestForKeyHandover() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = 'Key Handover';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest() { 
        Test.startTest();
        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = '123';
        request.serviceRequestId = '123';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }

    //------------------
    @isTest
    static void testHomeOrientationRequestX() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION;

        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDesnaggingRequestX() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION;

        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testKeyHandoverRequestX() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.resourceType = CustomerAPIConstants.STEP_KEY_HANDOVER;

        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testInvalidRequestX() {
        Test.startTest();
        GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper request = new GetHandoverAppointmentsWebService.GetAppointmentsRequestWrapper();
        request.unitId = '';
        request.serviceRequestId = '';
        request.resourceType = '';

        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/GetHandoverAppointments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        GetHandoverAppointmentsWebService.doPost();
        Test.stopTest();
    }
    
}