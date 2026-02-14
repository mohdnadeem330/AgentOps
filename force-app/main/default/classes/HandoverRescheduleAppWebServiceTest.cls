@isTest
public class HandoverRescheduleAppWebServiceTest {
    
    @isTest
    static void testValidRequest() {
        Test.startTest();
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Handover Appointments Operating Hours1';
        opHours.TimeZone = 'Asia/Dubai';
        insert opHours;
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.OperatingHoursId = opHours.Id;
        timeSlot.DayOfWeek = 'Monday';
        timeSlot.MaxAppointments = 5;
        timeSlot.StartTime = Time.newInstance(9, 0, 0, 0);
        timeSlot.EndTime = Time.newInstance(18, 0, 0, 0);
        insert timeSlot;
        
        ServiceTerritory serviceTerritoryRec = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = opHours.Id, IsActive = true);
        insert serviceTerritoryRec;
        
        WorkType wt = new WorkType(Name = 'Home Orientation - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert wt;
        
        WorkType wt2 = new WorkType(Name = 'Desnagging - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert wt2;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
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
        insert rec;
        
        ServiceAppointment rec2 = new ServiceAppointment();
        rec2.serviceTerritoryId = serviceTerritoryRec.Id;
        rec2.parentRecordId = acc.Id;
        rec2.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec2.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec2.additionalInformation = 'Test Additional Info';
        rec2.appointmentType = 'Handover';
        rec2.comments = 'Test Comments';
        rec2.WorkTypeId = wt.Id;
        rec2.RecordTypeId = handoverRT;
        insert rec2;
        
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
                                                             kar__c = UserInfo.getUserId(),
                                                             HandoverAgent__c = UserInfo.getUserId() );                                        
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
        
        Datetime startTime = Datetime.newInstanceGMT(2025, 05, 05, 11, 0, 0);
        Datetime endTime = Datetime.newInstanceGMT(2025, 05, 05, 12, 0, 0);
        
         Map<String, Object> homePrefs = new Map<String, Object>{
            'homeOrientationAttendees' => new List<String>{'Myself','Spouse / Family member'},
            'hoAppointmentsOther' => 'Kids also coming',
            'specialAccommodations' => new List<String>{'Language support'},
            'specialAccommodationsOther' => 'Need Arabic translator',
            'keyCollectionPreference' => 'Yes, an authorized representative will collect',
            'postHandoverContactPreferences' => new List<String>{'Email, WhatsApp'},
            'mortgageResaleAdvisorServices' => 'Mortgage services',
            'personalizedMoveInOffers' => new List<String>{'All of the above'},  
            'smartInstallationPreference' => 'Yes – Both',
            'minorAdjustments' => new List<String>{'Swimming pool installation'},
            'minorAdjustmentsOther' => 'Outdoor lighting'
        };
        
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();      
        String requestBody = JSON.serialize(new Map<String, Object>{
            'workTypeId' => wt.Id,
                'serviceAppointmentId' => rec.Id,
                'territoryId' => serviceTerritoryRec.Id,
                'startTime' => startTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
                'endTime' => endTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
                'serviceResourceId' => null,
                'unitId' => unit.Id,
                'serviceRequestId' => SR.Id,
                'homeOrientationtPreferences' => homePrefs
                });        
        req1.requestBody = Blob.valueOf(requestBody);
        req1.httpMethod = 'POST';        
        RestContext.request = req1;
        RestContext.response = res1;      
        HandoverRescheduleAppointmentWebService.doPost();
        
        RestRequest req2 = new RestRequest();
        RestResponse res2 = new RestResponse();      
        String requestBody2 = JSON.serialize(new Map<String, Object>{
            'workTypeId' => wt2.Id,
                'serviceAppointmentId' => rec2.Id,
                'territoryId' => serviceTerritoryRec.Id,
                'startTime' => startTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
                'endTime' => endTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
                'serviceResourceId' => null,
                'unitId' => unit.Id,
                'serviceRequestId' => SR.Id,
                'homeOrientationtPreferences' => homePrefs
                });        
        req2.requestBody = Blob.valueOf(requestBody2);
        req2.httpMethod = 'POST';        
        RestContext.request = req2;
        RestContext.response = res2;      
        HandoverRescheduleAppointmentWebService.doPost();
        
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest1() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = null;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        HandoverRescheduleAppointmentWebService.doPost();   
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest2() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'workTypeId' => 'ABC',
                'serviceAppointmentId' => 'ABC',
                'territoryId' => 'ABC',
                'startTime' => null,
                'endTime' => null,
                'serviceResourceId' => 'ABC',
                'unitId' => 'ABC',
                'serviceRequestId' => 'ABC'
                });        
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        HandoverRescheduleAppointmentWebService.doPost();   
        Test.stopTest();
    }    
}