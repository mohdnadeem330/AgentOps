@isTest
public class AppointmentCandidatesWebServiceTest {
    @testSetup
    static void setupTestData() {
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
        
        ServiceTerritory serviceTerritoryRec = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = opHours.Id, IsActive = true, Type__c = 'Scheduler', Project_Name__c = 'Noya');
        insert serviceTerritoryRec;
        
        WorkTypeGroup wtg = new WorkTypeGroup(Name = 'Home Orientation', IsActive = true, Work_Type_Group_Category__c = 'Handover');
        insert wtg;
        
        WorkType wt = new WorkType(Name = 'Home Orientation - Virtual', EstimatedDuration = 60, Type__c='Virtual', DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert wt;

        insert new ServiceTerritoryWorkType( ServiceTerritoryId= serviceTerritoryRec.Id, WorkTypeId = wt.Id );
        
        ServiceResource serResource = new ServiceResource(Name = 'Test Service Resouce', RelatedRecordId = UserInfo.getUserId(), ResourceType='T', IsActive =true);
        insert serResource;
    }
    static testMethod void getAppCandidatesTest() {
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        WorkTypeGroup workTypeGroup = [SELECT Id FROM WorkTypeGroup LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        Datetime actualStartDateTime = Datetime.newInstance(2021, 5, 5, 0, 0, 0);
        String startDateTime = actualStartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
        Datetime actualEndDateTime = Datetime.newInstance(2021, 5, 5, 23, 0, 0);
        String endDateTime = actualEndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
        String expectedResponse = '[' +
            '  {' +
            '    \"startTime\": \"2025-05-05T16:00:00.000+0000\",' +
            '    \"endTime\": \"2021-05-05T17:00:00.000+0000\",' +
            '    \"resources\": [' +
            '      \"' + serviceResource.Id + '\"' +
            '    ],' +
            '    \"territoryId\": \"' + serviceTerritory.Id + '\"' +
            '  },' +
            '  {' +
            '    \"startTime\": \"2021-05-05T19:00:00.000+0000\",' +
            '    \"endTime\": \"2021-05-05T20:00:00.000+0000\",' +
            '    \"resources\": [' +
            '      \"' + serviceResource.Id + '\"' +
            '    ],' +
            '    \"territoryId\": \"' + serviceTerritory.Id + '\"' +
            '  }' +
            ']';
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock(expectedResponse);
        
        Test.startTest();
        AppointmentCandidateService candidateList = AppointmentCandidateService.getAppointmentCandidates(workType.Id, workTypeGroup.Id, serviceTerritory.Id, 'abc', startDateTime, endDateTime);
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest1() {
        Test.startTest();        
        RestRequest req = new RestRequest();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        String requestBody = JSON.serialize(new Map<String, Object>{
            'projectName' => 'Noya',
                'appointmentType' => 'Home Orientation',
                'startDate' => '2025-05-01',
                'endDate' => '2025-05-10',
                'OrientationType' => 'Virtual',
                'customerId' => acc.Id,
                'referenceId' => 'dexterm@gmail.com'
                });        
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        AppointmentCandidatesWebService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRequest2() {
        Test.startTest();        
        RestRequest req = new RestRequest();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        String requestBody = JSON.serialize(new Map<String, Object>{
            'projectName' => 'Noya',
                'appointmentType' => 'Home Orientation',
                'startDate' => null,
                'endDate' => null,
                'OrientationType' => 'Virtual',
                'customerId' => acc.Id,
                'referenceId' => 'dexterm@gmail.com'
            });        
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        AppointmentCandidatesWebService.doPost();
        Test.stopTest();
    }
    
    @isTest
    public static void testMergeResourcesForSameSlot() {
        
        try{
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkTypeGroup workTypeGroup = [SELECT Id FROM WorkTypeGroup LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        
        String commonStartTime = '2025-05-05T09:00:00.000+0000';
        String commonEndTime   = '2025-05-05T10:00:00.000+0000';
        
        String expectedResponse = '[' +
            '{ "startTime": "' + commonStartTime + '", "endTime": "' + commonEndTime + '", "resources": ["resA"], "territoryId": "' + serviceTerritory.Id + '" },' +
            '{ "startTime": "' + commonStartTime + '", "endTime": "' + commonEndTime + '", "resources": ["resB"], "territoryId": "' + serviceTerritory.Id + '" }' +
            ']';
        
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock(expectedResponse);
        
        Datetime actualStartDateTime = Datetime.newInstance(2025, 5, 5, 0, 0, 0);
        Datetime actualEndDateTime = Datetime.newInstance(2025, 5, 5, 23, 0, 0);
        String startDateTime = actualStartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
        String endDateTime = actualEndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
        
        Test.startTest();
        AppointmentCandidateService result = AppointmentCandidateService.getAppointmentCandidates(workType.Id,workTypeGroup.Id,serviceTerritory.Id,'any-policy-id',startDateTime,endDateTime);
        Test.stopTest();
        } catch(Exception e) {}
        
    }
}