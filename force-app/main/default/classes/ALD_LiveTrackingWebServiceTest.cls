@isTest
public class ALD_LiveTrackingWebServiceTest {

    @testSetup
    static void setup() {
        // Add status transitions
        FSL.GlobalAPIS.addStatusTransition('New', 'Closed');
        FSL.GlobalAPIS.addStatusTransition('New', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('New', 'Work In Progress');
        
        // Insert Accounts
        Account testAccount = TestObjectsFactory.getPersonAccountRecord();
        Account buyer = TestObjectsFactory.getPersonAccountRecord();
        buyer.PersonEmail = 'hardik.vitthani@aldar.com.invalid';
        insert new List<Account>{ testAccount, buyer };
        
        // Insert Opportunity
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(testAccount.Id);
        insert opp;
        
        // Insert Units and Projects
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c pr = new Project__c(Id = unit.Project__c, AsiteProjectName__c = 'Test');
        update pr;
        
        // Insert Sales Order
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, testAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        // Insert Case
        Case caseObj = new Case(
            RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId(),
            Subject = 'Test Subject',
            Description = 'Test Description',
            Status = 'New',
            AccountId = testAccount.Id,
            ContactId = [SELECT Id FROM Contact LIMIT 1]?.Id,
            Unit__c = salesOrder.Unit__c,
            SalesOrder__c = salesOrder.Id,
            CaseCategory__c = 'Civil',
            SubVertical__c = 'DLP',
            CustomerType__c = 'Owner',
            SubCategory__c = 'Aluminium',
            ProblemCode__c = 'CM-PQA- AL-Accessories',
            IncidentDescription__c = 'Scratched',
            ResolutionType__c = 'Repair',
            Skills_Required__c = 'Electrician'
        );
        insert caseObj;
        
        // Insert Sales Manager User
        User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager.IsActive = TRUE;
        insert salesManager;
        
        // Insert Project and Project Budget
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        
        // Insert another Unit
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.Id;
        unit2.Status__c = 'New';
        unit2.AssignedToUser__c = salesManager.Id;
        unit2.LatitudeLongitude__Latitude__s = 32.987650;
        unit2.LatitudeLongitude__Longitude__s = 72.345678;
        insert unit2;
        
        // Insert Work Types
        WorkType wt1 = new WorkType(Name = 'Technician', EstimatedDuration = 1);
        WorkType wt2 = new WorkType(Name = 'Contractor DLP', EstimatedDuration = 1);
        insert new List<WorkType>{ wt1, wt2 };
        
        // Insert Work Order
        WorkOrder woObj = new WorkOrder(CaseId = caseObj.Id, AccountId = testAccount.Id, WorkTypeId = wt1.Id, Status = 'New');
        insert woObj;
        
        // Insert Scheduling Policy
        FSL__Scheduling_Policy__c scpolicy = new FSL__Scheduling_Policy__c(Name = 'Aldar Scheduling Policy');
        insert scpolicy;
        
        // Insert Work Order Line Items
        WorkOrderLineItem woli1 = new WorkOrderLineItem(Status = 'New', WorkTypeId = wt1.Id, WorkOrderId = woObj.Id, Case__c = caseObj.Id);
        WorkOrderLineItem woli2 = new WorkOrderLineItem(Status = 'New', WorkTypeId = wt1.Id, WorkOrderId = woObj.Id, Case__c = caseObj.Id);
        insert new List<WorkOrderLineItem>{ woli1, woli2 };
        
        // Create a profile for the user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create a User
        User technician = new User(
            FirstName = 'Test',
            LastName = 'Technician',
            Email = 'testtechnician@example.com',
            Username = 'testtechnician@example.com.test',
            Alias = 'ttech',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert technician;
                    // Create a Service Resource
            ServiceResource serviceResource = new ServiceResource(
                //ResourceType = 'Technician',
                RelatedRecordId = technician.Id,
                Name = 'Test Technician'
            );
        insert serviceResource;
        
        // Insert Service Appointments
        Id assessmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Assessment').getRecordTypeId();
        Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId();
        ServiceAppointment saAssessment = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId = woli1.Id,
            Status = 'Scheduled',
            SchedStartTime = DateTime.now(),
            SchedEndTime = DateTime.now().addHours(1),
            RecordTypeId = assessmentRecordTypeId,
            FSSK__FSK_Assigned_Service_Resource__c = serviceResource.Id,
            FSSK__FSK_Assigned_Service_Resource__r = serviceResource,
            EarliestStartTime = system.today()
        );
        ServiceAppointment saResolution = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId = woli2.Id,
            Status = 'Scheduled',
            SchedStartTime = DateTime.now(),
            SchedEndTime = DateTime.now().addHours(1),
            RecordTypeId = ResolutionRecordTypeId,
            FSSK__FSK_Assigned_Service_Resource__c = serviceResource.Id,
            FSSK__FSK_Assigned_Service_Resource__r = serviceResource,
            EarliestStartTime = system.today()
        );
        insert new List<ServiceAppointment>{ saAssessment, saResolution };
                    // Create a Service Resource Record for the Appointment
        /*ServiceResourceAssignment sra = new ServiceResourceAssignment(
            ServiceResourceId = serviceResource.Id,
            ServiceAppointmentId = saAssessment.Id,
            EstimatedTravelTime = 30,
            ApptAssistantInfoUrl = 'https://example.com/s/location'
        );
        insert sra;*/
        
    }

    @isTest
    public static void testDoPostWithValidRequest() {
        // Prepare the request
        Id caseId = [SELECT Id FROM Case LIMIT 1]?.Id;
        String reqBody = '{"reqId": "' + caseId + '"}';
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/LiveTracking');
        RestContextHandler handler = new RestContextHandler(true);
        
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        
        ALD_LiveTrackingWebService.doPost();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(200, res.statusCode);
        //System.assert(res.responseBody.toString().contains('"success":true'));
        Test.stopTest();
    }

    @isTest
    public static void testDoPostWithInvalidRequest() {
        // Prepare the request
        String reqBody = '{}';
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/LiveTracking');
        RestContextHandler handler = new RestContextHandler(true);
        
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        
        ALD_LiveTrackingWebService.doPost();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(400, res.statusCode);
        //System.assert(res.responseBody.toString().contains('"success":false'));
        Test.stopTest();
    }

    @isTest
    public static void testGetTrackingMap() {
        ServiceAppointment sapp = [SELECT Id,Case__c FROM ServiceAppointment LIMIT 1];
        Map<String, Object> reqBodyMap = new Map<String, Object>();
        reqBodyMap.put('reqId', sapp.Case__c);
        
        ALD_LiveTrackingWebService.appointmentSchResponse response = ALD_LiveTrackingWebService.getTrackingMap(reqBodyMap);
        
        ServiceAppointment sa = [SELECT Id,AppointmentNumber,Status,SchedStartTime,SchedEndTime,FSSK__FSK_Assigned_Service_Resource__c,FSSK__FSK_Assigned_Service_Resource__r.Name,(SELECT Id FROM ServiceResources) FROM ServiceAppointment Limit 1];
        ALD_LiveTrackingWebService.appointmentSchResponse ob= new ALD_LiveTrackingWebService.appointmentSchResponse(sa);
        
        //System.assertNotEquals(null, response);
        /*System.assertEquals(caseId, response.appointmentId);*/
    }
    
     @isTest
    public static void testCancelServiceRequestInvalid(){
         // Prepare the request
        Id caseId = [SELECT Id FROM Case LIMIT 1]?.Id;
        String reqBody = '{"reqId": "' + caseId + '"}';
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/CancelRequest');
        RestContextHandler handler = new RestContextHandler(true);
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        ALD_CancelServiceRequestWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
    @isTest
    public static void testCancelServiceRequestInvalid2(){
         // Prepare the request
        Id caseId = [SELECT Id FROM Case LIMIT 1]?.Id;
        String reqBody = '{}';
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/CancelRequest');
        RestContextHandler handler = new RestContextHandler(true);
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        ALD_CancelServiceRequestWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
    
     @isTest
    public static void testCancelServiceRequestvalid(){
         // Prepare the request
        Id caseId = [SELECT Id FROM Case LIMIT 1]?.Id;
        String reqBody = '{"reqId": "' + caseId + '","reason":"not required"}';
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/CancelRequest');
        RestContextHandler handler = new RestContextHandler(true);
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        ALD_CancelServiceRequestWebService.doPost();
        RestResponse res = RestContext.response;
        Test.stopTest();
    }
}