@isTest
public class AMC_ODBookAppointmentControllerTest {
	@testSetup
    static void setup() {
        // Add status transitions
        FSL.GlobalAPIS.addStatusTransition('New', 'Closed');
        FSL.GlobalAPIS.addStatusTransition('New', 'Work In Progress');
        
        // Insert Accounts
        Account testAccount = TestObjectsFactory.getPersonAccountRecord();
        Account buyer = TestObjectsFactory.getPersonAccountRecord();
        buyer.PersonEmail = 'hardik.vitthani@aldar.com.invalid';
        insert new List<Account>{ testAccount, buyer };
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
        test.startTest();
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
            CaseCategory__c = 'MEP',
            SubVertical__c = 'DLP',
            CustomerType__c = 'Owner',
            SubCategory__c = 'HVAC',
            ProblemCode__c = 'CM-PQA-AC Function',
            IncidentDescription__c = 'tripping',
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
        // Create Operating Hours
        OperatingHours operatingHours = new OperatingHours(
            Name = 'Gold Appointments Calendar' 
        );
        insert operatingHours;
		// Create Operating Hours Time Slots
        List<TimeSlot> lstTimeSl = new List<TimeSlot>();
        TimeSlot  monTimeSlot = new TimeSlot (
            OperatingHoursId = operatingHours.Id,
            DayOfWeek = 'Monday',
            StartTime = Time.newInstance(8, 0, 0, 0),
            EndTime = Time.newInstance(17, 0, 0, 0)
        );
        lstTimeSl.add( monTimeSlot);

        TimeSlot tueTimeSlot = new TimeSlot(
            OperatingHoursId = operatingHours.Id,
            DayOfWeek = 'Thursday',
            StartTime = Time.newInstance(8, 0, 0, 0),
            EndTime = Time.newInstance(17, 0, 0, 0)
        );
        lstTimeSl.add( tueTimeSlot);
		TimeSlot thursdaysl = new TimeSlot(
            OperatingHoursId = operatingHours.Id,
            DayOfWeek = 'Tuesday',
            StartTime = Time.newInstance(8, 0, 0, 0),
            EndTime = Time.newInstance(17, 0, 0, 0)
        );
       lstTimeSl.add( thursdaysl);
        INSERT 	lstTimeSl;
        ServiceTerritory terr = new ServiceTerritory(
        	Name = 'ABC',
            OperatingHoursId  = operatingHours.Id,
            IsActive =true
        );
        INSERT terr;
        
        ServiceResource serviceResource = new ServiceResource(
            RelatedRecordId = technician.Id,
            Name = 'Test Technician',
            DLP_Resource_Category__c='DLP Executive',
            IsActive=TRUE
        );
        insert serviceResource;
        
        ServiceTerritoryMember mem = new ServiceTerritoryMember (
            ServiceTerritoryId = terr.Id,
            ServiceResourceId = serviceResource.Id,
            EffectiveStartDate=Date.today().addDays(-1)//.addDays(-1)
        );
        INSERT mem; 
        
        // Insert Work Order Line Items
        WorkOrderLineItem woli1 = new WorkOrderLineItem(Status = 'New', WorkTypeId = wt1.Id, WorkOrderId = woObj.Id, Case__c = caseObj.Id);
        WorkOrderLineItem woli2 = new WorkOrderLineItem(Status = 'New', WorkTypeId = wt1.Id, WorkOrderId = woObj.Id, Case__c = caseObj.Id);
        insert new List<WorkOrderLineItem>{ woli1, woli2 };
        
        // Insert Service Appointments
        Id assessmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Assessment').getRecordTypeId();
       
        ServiceAppointment saAssessment = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId = woli1.Id,
            Status = 'New',
            RecordTypeId = assessmentRecordTypeId,
            Duration=1,
            EarliestStartTime = system.today()
        );
       
        insert new List<ServiceAppointment>{ saAssessment };
            test.stopTest();
    }
     @isTest
    public static void testFetchAppointmentSlot() {
        Id appId = [SELECT Id FROM ServiceAppointment LIMIT 1]?.Id;
        AMC_ODBookAppointmentController.FetchAvailableSlots(appId);
        AMC_ODBookAppointmentController.MainWrapper wrp = new AMC_ODBookAppointmentController.MainWrapper();
        wrp.day = '10 Sep 2025';
        AMC_ODBookAppointmentController.TimingDetail tm = new AMC_ODBookAppointmentController.TimingDetail('09:00 AM','10:00 AM',DateTime.Now(),DateTime.Now().addHours(1));
         FSL__Scheduling_Policy__c policy=[select id ,Name  from FSL__Scheduling_Policy__c where Name='Aldar Scheduling Policy' LIMIT 1];
        AMC_ODBookAppointmentController.scheduleAppointment(appId,DateTime.Now(),DateTime.Now().addHours(1));
        Map<Date, List<DateTime>> mapDtTime = new Map<Date, List<DateTime>> ();
        mapDtTime.put(Date.Today(),new List<dateTime>());//{DateTime.Now(),DateTime.Now().addHours(1)}
        mapDtTime.get(Date.Today()).add(DateTime.Now());
        mapDtTime.get(Date.Today()).add(DateTime.Now().addHours(1));
        AMC_ODBookAppointmentController.formatAndReturnDayWiseSlot(Date.Today(),mapDtTime,1);
    }
    
}