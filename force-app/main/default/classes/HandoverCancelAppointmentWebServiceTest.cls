@isTest
public class HandoverCancelAppointmentWebServiceTest {
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
        insert wt;
        
        WorkType wtDesnag = new WorkType(Name = 'Desnagging - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert wtDesnag;
        
        WorkType wtKeyHand = new WorkType(Name = 'Key Handover - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert wtKeyHand;
        
        Id handoverRT = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Handover').getRecordTypeId();
        
        ServiceAppointment rec = new ServiceAppointment();
        rec.serviceTerritoryId = serviceTerritoryRec.Id;
        rec.parentRecordId = acc.Id;
        rec.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec.additionalInformation = 'Test Additional Info';
        rec.appointmentType = 'Handover';
        rec.comments = 'Test Comments for Home Orientation';
        rec.WorkTypeId = wt.Id;
        rec.RecordTypeId = handoverRT;
        rec.Status = 'Scheduled';
        insert rec;
        
        ServiceAppointment recDesnag = new ServiceAppointment();
        recDesnag.serviceTerritoryId = serviceTerritoryRec.Id;
        recDesnag.parentRecordId = acc.Id;
        recDesnag.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        recDesnag.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        recDesnag.additionalInformation = 'Test Additional Info';
        recDesnag.appointmentType = 'Handover';
        recDesnag.comments = 'Test Comments for Desnagging';
        recDesnag.WorkTypeId = wtDesnag.Id;
        recDesnag.RecordTypeId = handoverRT;
        recDesnag.Status = 'Scheduled';
        insert recDesnag;
        
        ServiceAppointment recKeyHand = new ServiceAppointment();
        recKeyHand.serviceTerritoryId = serviceTerritoryRec.Id;
        recKeyHand.parentRecordId = acc.Id;
        recKeyHand.schedStartTime = Datetime.valueOf('2025-05-06 09:00:00');
        recKeyHand.schedEndTime = Datetime.valueOf('2025-05-06 10:00:00');
        recKeyHand.additionalInformation = 'Test Additional Info';
        recKeyHand.appointmentType = 'Handover';
        recKeyHand.comments = 'Test Comments For Key Handover';
        recKeyHand.WorkTypeId = wtKeyHand.Id;
        recKeyHand.RecordTypeId = handoverRT;
        recKeyHand.Status = 'Scheduled';
        insert recKeyHand;
        
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
                                                             Desnagging_Appointment__c = recDesnag.Id,
                                                             Key_Handover_Appointment__c = recKeyHand.Id
                                                            );                                        
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
        ServiceAppointment serAppointment= [SELECT Id,comments FROM ServiceAppointment Where comments = 'Test Comments for Home Orientation' LIMIT 1];
        serviceResource serResource= [SELECT Id FROM serviceResource LIMIT 1];
        ServiceTerritory serTerritory= [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType workType= [SELECT Id,Name FROM WorkType Where Name = 'Home Orientation - Scheduled' LIMIT 1];
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = new HandoverCancelAppointmentWebService.CancelAppointmentWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.serviceAppointmentId = serAppointment.Id;
        request.workTypeId = workType.Id;
        request.territoryId = serTerritory.Id;
        Datetime startTime = Datetime.valueOf('2025-05-05 09:00:00');
        Datetime endTime = Datetime.valueOf('2025-05-05 10:00:00');
        request.startTime = startTime.format('yyyy-MM-dd HH:mm:ss');
        request.endTime = endTime.format('yyyy-MM-dd HH:mm:ss'); 
        request.serviceResourceId = serResource.Id;
        request.cancellationReason = 'Test';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        HandoverCancelAppointmentWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testValidRequestForDesnagging() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        WorkType workType= [SELECT Id FROM WorkType Where Name = 'Desnagging - Scheduled' LIMIT 1];
        ServiceAppointment serAppointment= [SELECT Id,comments From ServiceAppointment Where comments = 'Test Comments for Desnagging' LIMIT 1];
        serviceResource serResource= [SELECT Id FROM serviceResource LIMIT 1];
        ServiceTerritory serTerritory= [SELECT Id FROM ServiceTerritory LIMIT 1];
        
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = new HandoverCancelAppointmentWebService.CancelAppointmentWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.serviceAppointmentId = serAppointment.Id;
        request.workTypeId = workType.Id;
        request.territoryId = serTerritory.Id;
        Datetime startTime = Datetime.valueOf('2025-05-06 09:00:00');
        Datetime endTime = Datetime.valueOf('2025-05-06 10:00:00');
        request.startTime = startTime.format('yyyy-MM-dd HH:mm:ss');
        request.endTime = endTime.format('yyyy-MM-dd HH:mm:ss'); 
        request.serviceResourceId = serResource.Id;
        request.cancellationReason = 'Test';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        HandoverCancelAppointmentWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testValidRequestForKeyHandover() {
        Test.startTest();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        WorkType workType= [SELECT Id FROM WorkType Where Name = 'Key Handover - Scheduled' LIMIT 1];
        ServiceAppointment serAppointment= [SELECT Id,comments From ServiceAppointment Where comments = 'Test Comments For Key Handover' LIMIT 1];
        serviceResource serResource= [SELECT Id FROM serviceResource LIMIT 1];
        ServiceTerritory serTerritory= [SELECT Id FROM ServiceTerritory LIMIT 1];
        
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = new HandoverCancelAppointmentWebService.CancelAppointmentWrapper();
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;
        request.serviceAppointmentId = serAppointment.Id;
        request.workTypeId = workType.Id;
        request.territoryId = serTerritory.Id;
        Datetime startTime = Datetime.valueOf('2025-05-07 09:00:00');
        Datetime endTime = Datetime.valueOf('2025-05-07 10:00:00');
        request.startTime = startTime.format('yyyy-MM-dd HH:mm:ss');
        request.endTime = endTime.format('yyyy-MM-dd HH:mm:ss'); 
        request.serviceResourceId = serResource.Id;
        request.cancellationReason = 'Test';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        HandoverCancelAppointmentWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest() {
        Test.startTest();
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = new HandoverCancelAppointmentWebService.CancelAppointmentWrapper();
        request = null;
        
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        HandoverCancelAppointmentWebService.doPost();
        RestResponse res = RestContext.response;
    }
    
    @isTest
    static void populateRestHandlerTest() {
        //RestContextHandler handler = new RestContextHandler(true);
        //handler.response = new WebServiceResponse();
        //handler.restRequest = RestContext.request;
        //handler.restResponse = RestContext.response;
        //HandoverCancelAppointmentWebService.populateRestHandler(handler, false, 404, '123');
    }

	//----


    @isTest
    static void testCancelHomeOrientationAppointmentX() {
        Test.startTest();
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = prepareRequest('Test Comments for Home Orientation', 'Home Orientation - Scheduled');
        invokeWebService(request);
        Test.stopTest();
    }

    @isTest
    static void testCancelDesnaggingAppointmentX() {
        Test.startTest();
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = prepareRequest('Test Comments for Desnagging', 'Desnagging - Scheduled');
        invokeWebService(request);
        Test.stopTest();
    }

    @isTest
    static void testCancelKeyHandoverAppointmentX() {
        Test.startTest();
        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = prepareRequest('Test Comments For Key Handover', 'Key Handover - Scheduled');
        invokeWebService(request);
        Test.stopTest();
    }

    @isTest
    static void testInvalidPayloadX() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(''); // Empty body

        RestContext.request = req;
        RestContext.response = new RestResponse();

        HandoverCancelAppointmentWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testNullRequestObjectX() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(null));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        HandoverCancelAppointmentWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testPopulateRestHandlerMethodX() {
        //RestContextHandler handler = new RestContextHandler(true);
        //handler.response = new WebServiceResponse();
        //handler.restRequest = RestContext.request;
        //handler.restResponse = RestContext.response;
        //HandoverCancelAppointmentWebService.populateRestHandler(handler, false, 400, 'Bad Request');
    }

    //
    public static HandoverCancelAppointmentWebService.CancelAppointmentWrapper prepareRequest(String comment, String workTypeName) {
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment WHERE comments = :comment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType WHERE Name = :workTypeName LIMIT 1];

        Datetime startTime = Datetime.now();
        Datetime endTime = startTime.addHours(1);

        HandoverCancelAppointmentWebService.CancelAppointmentWrapper request = new HandoverCancelAppointmentWebService.CancelAppointmentWrapper();
        request.serviceAppointmentId = appointment.Id;
        request.workTypeId = workType.Id;
        request.territoryId = territory.Id;
        request.startTime = startTime.format('yyyy-MM-dd HH:mm:ss');
        request.endTime = endTime.format('yyyy-MM-dd HH:mm:ss');
        request.serviceResourceId = resource.Id;
        request.cancellationReason = 'Test Cancellation';
        request.unitId = unit.Id;
        request.serviceRequestId = sr.Id;

        return request;
    }

    static void invokeWebService(HandoverCancelAppointmentWebService.CancelAppointmentWrapper request) {
        RestRequest req = new RestRequest();
        req.requestUri = '/LiveAldar/CancelServiceAppointment';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(request));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        HandoverCancelAppointmentWebService.doPost();
    }
}