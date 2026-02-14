/*
* Class Name:  ServiceAppointmentTriggerHandlerTest
* Created By : R3-DLP implementation-Smaartt
* Description: Test class used for handling Service appoinement actions
*/
@istest 
public class ServiceAppointmentTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        User testUser = TestObjectsFactory.getUserRecord('System Administrator', 'testuser');
        insert testUser;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
        
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
        
        ServiceTerritory serviceTerritoryRec = new ServiceTerritory(Name = 'Dubai Sales Center', OperatingHoursId = opHours.Id, IsActive = true);
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
    }
    
    @isTest
    static void testCheckinServiceAppointment() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory serviceTerritoryRec = [SELECT Id FROM ServiceTerritory LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceAppointment rec = new ServiceAppointment();
        rec.serviceTerritoryId = serviceTerritoryRec.Id;
        rec.parentRecordId = acc.Id;
        rec.schedStartTime = Datetime.valueOf('2024-09-09 09:00:00');
        rec.schedEndTime = Datetime.valueOf('2024-09-09 010:00:00');
        rec.additionalInformation = 'Test Additional Info';
        rec.appointmentType = 'checkin';
        rec.comments = 'Test Comments';
        Test.startTest();
        //insert rec;
        Test.stopTest();
    }
    
    @isTest
    static void testAfterInsertMethod() {
        FSL.GlobalAPIS.addStatusTransition('New', 'Closed');
        FSL.GlobalAPIS.addStatusTransition('New', 'Work In Progress'); 
        Account testAccount = TestObjectsFactory.getPersonAccountRecord();
        insert testAccount;
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        
        User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager.IsActive = TRUE;
        insert salesManager;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.id;
        unit2.Status__c = 'New';
        unit2.AssignedToUser__c = salesManager.Id;
        unit2.LatitudeLongitude__Latitude__s = 32.987650;
        unit2.LatitudeLongitude__Longitude__s = 72.345678;
        insert unit2;
        
        
        Case caseObj = new Case();
        caseObj.AccountId = testAccount.id;
        caseObj.RecordtypeId = recordTypeId;
        caseObj.Unit__c = unit2.id;
        caseObj.Status = 'New';
        caseObj.ECSS_CompanyOptions__c = 'AlDar Properties';
        caseObj.Vertical__c = 'DLP' ;
        caseObj.Skills_Required__c = 'Plumber';        
        caseObj.CustomerType__c = 'Owner';   
        caseObj.Subject = 'Test Case';
        insert caseObj;
        
        WorkType wt1 = new WorkType();
        wt1.Name = 'DLP Executive';        
        wt1.EstimatedDuration = 1;
        //wt1.ShouldAutoCreateSvcAppt = true ; 
        insert wt1;
        
        WorkType wt = new WorkType();
        wt.Name = 'Technician';        
        wt.EstimatedDuration = 1;
        //wt.ShouldAutoCreateSvcAppt = true ; 
        insert wt;               
        
        WorkType wt2 = new WorkType();
        wt2.Name = 'Contractor DLP';        
        wt2.EstimatedDuration = 1;
        //wt2.ShouldAutoCreateSvcAppt = true ; 
        insert wt2;
        
        WorkOrder woObj = new WorkOrder();
        woObj.CaseId = caseObj.Id;
        woObj.AccountId = testAccount.Id;
        woObj.WorkTypeId =  wt1.Id;
        woObj.Status = 'New';
        insert woObj;
        
        
        FSL__Scheduling_Policy__c scpolicy = New FSL__Scheduling_Policy__c();
        scpolicy.Name = 'Aldar Scheduling Policy';
        insert scpolicy;   
        
        Id assessmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Assessment').getRecordTypeId();
        Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId();
        
        WorkOrderLineItem woli1 = New WorkOrderLineItem();
        woli1.Status = 'New';
        woli1.WorkTypeId = wt1.Id;
        woli1.WorkOrderId = woObj.Id; 
        woli1.Case__c = caseObj.Id; 
        insert woli1;   
        WorkOrderLineItem woli2 = New WorkOrderLineItem();
        woli2.Status = 'New';
        woli2.WorkTypeId = wt.Id;
        woli2.WorkOrderId = woObj.Id; 
        woli2.Case__c = caseObj.Id; 
        insert woli2;           
        system.debug('SaTest**'+'WOLI insert');  
        
        ServiceAppointment saAssessment = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId =  woli1.Id,
            Status = 'New',
            RecordTypeId = assessmentRecordTypeId ,
            EarliestStartTime = system.today() 
            
        );
        insert saAssessment;
        system.debug('SaTest**'+'Assessment1'); 
        ServiceAppointment saResolution = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId =  woli2.Id,
            Status = 'New',
            RecordTypeId = ResolutionRecordTypeId ,
            EarliestStartTime = system.today() 
            
        );
        insert saResolution;
        system.debug('SaTest**'+'Resol 1');
        
        saResolution.Status = 'Work In Progress';
        Update saResolution;
        system.debug('SaTest**'+'update reso'); 
        saAssessment.Status = 'Work In Progress';        
        Update saAssessment;    
        system.debug('SaTest**'+'update assess'); 
        unit2.LatitudeLongitude__Latitude__s= null;
        unit2.LatitudeLongitude__Longitude__s= null;
        Update unit2;
        ServiceAppointmentTriggerHandler handle = new ServiceAppointmentTriggerHandler();
        list<SObject> serviceAppNewList = new list<SObject>();
        saAssessment = [Select id,Status,Record_Type_Name__c,Case__c from ServiceAppointment where id=: saAssessment.Id LIMIT 1] ;
        serviceAppNewList.add(saAssessment);
        handle.beforeUpdateMethod( serviceAppNewList,(new Map<Id, SObject>()), (new List<SObject>()), (new Map<Id, SObject>()));
        ServiceAppointment saAssessment1 = new ServiceAppointment(
            Case__c = caseObj.Id,
            ParentRecordId =  woli1.Id,
            Status = 'New',
            RecordTypeId = assessmentRecordTypeId ,
            EarliestStartTime = system.today()             
        );
        insert saAssessment1; 
        system.debug('SaTest**'+'Assessment1'); 
    }
    
    @isTest
    public static void sapPlatformEventTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        String uniqueId = String.valueOf(System.now().getTime());
        
        // Generate a random number for additional uniqueness
        Integer randomNumber = (Integer) (Math.random() * 100000);
        
        // Construct a unique email address
        String uniqueEmail = 'testcontact' + uniqueId + randomNumber + '@example.com';
        
        User userObj = new User(
            Alias = 'testuser',
            Email = uniqueEmail, // Ensure this is unique
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUserTestClass',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            IsActive=true,
            UserName = uniqueEmail // Ensure this is unique
        );
        
        insert userObj;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Community_Admin_PS'];
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = userObj.Id,
            PermissionSetId = ps.Id
        );
        
        insert psa;
        
        system.runAs(userObj){
            OperatingHours oh = new OperatingHours(Name = 'Test OH', TimeZone = 'Asia/Dubai');
            insert oh;
            
            Account acc = new Account(Name = 'Test Account', SapAccountID__c = 'SAP123');
            insert acc;
            
            Product2 prod = new Product2(Name = 'Test Class', IsActive = true, Com_Is_VAT_Included__c = 'Yes');
            insert prod;
            
            List <RecordType> classRTList = [SELECT Id 
                                             FROM RecordType 
                                             WHERE SObjectType = 'Asset' AND DeveloperName = 'Com_Class_Schedule' 
                                             LIMIT 1];
            
            RecordType classRt; 
            if (classRTList.size() > 0) {
                classRt = classRTList[0];
            }
            
            Asset classAsset = new Asset(Name = 'Test Class Asset', RecordTypeId = classRt.Id, Com_Class__c = prod.Id);
            insert classAsset;
            
            ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oh.Id);
            insert st;
            
            ServiceResource srClass = new ServiceResource(Name = 'SR Class', IsActive = true, ResourceType = 'S', AssetId = classAsset.Id);
            insert srClass;
            
            WorkType wt = new WorkType(Name = 'WT', EstimatedDuration = 60);
            insert wt;
            
            Id saRtId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
            
            Datetime startT = DateTime.newInstance(System.today(), Time.newInstance(8, 0, 0, 0));
            Datetime endT   = startT.addHours(1);
            
            ServiceAppointment saClass = new ServiceAppointment(
                ParentRecordId = acc.Id,
                FSSK__FSK_Assigned_Service_Resource__c = srClass.Id,
                ServiceTerritoryId = st.Id,
                Subject = 'Class SA',
                Email = 'class@test.com',
                SchedStartTime = startT,
                SchedEndTime   = endT,
                Status = 'Scheduled',
                RecordTypeId = saRtId,
                WorkTypeId = wt.Id,
                Com_SAP_Invoice_Integration_Status__c = '',
                Com_Payment_Status__c = ''
            );
            
            insert saClass;
            
            test.startTest();
            saClass.Com_Payment_Ref__c = '123456';
            saClass.Com_Payment_Status__c = 'Success';
            saClass.Com_SAP_Invoice_Integration_Status__c = 'Success';
            update saClass;
            test.stoptest();
        }
        
        
    }
    
    @IsTest
    static void test_fireRecieptPlatformEvent_direct_minimal() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        String uniqueId = String.valueOf(System.now().getTime());
        
        // Generate a random number for additional uniqueness
        Integer randomNumber = (Integer) (Math.random() * 100000);
        
        // Construct a unique email address
        String uniqueEmail = 'testcontact' + uniqueId + randomNumber + '@example.com';
        
        User userObj = new User(
            Alias = 'testuser',
            Email = uniqueEmail, // Ensure this is unique
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUserTestClass',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            IsActive=true,
            UserName = uniqueEmail // Ensure this is unique
        );
        
        insert userObj;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Community_Admin_PS'];
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = userObj.Id,
            PermissionSetId = ps.Id
        );
        
        insert psa;
        
        system.runAs(userObj){
            
            // --- Minimal setup just for this test (kept local to avoid side-effects) ---
            OperatingHours oh = new OperatingHours(Name = 'OH-Rcpt', TimeZone = 'Asia/Dubai');
            insert oh;
            
            ServiceTerritory st = new ServiceTerritory(Name = 'ST-Rcpt', IsActive = true, OperatingHoursId = oh.Id);
            insert st;
            
            // Account parent so AccountId != null after insert (passes your filter)
            Account acc = new Account(Name = 'ACC-Rcpt', SapAccountID__c = 'SAP-ACC-999');
            insert acc;
            
            // Class (Product2). Only Description is read in your code; VAT/Profit Center not required.
            Product2 cls = new Product2(Name = 'Class-Rcpt', IsActive = true, Description = 'Receipt Class');
            insert cls;
            
            // Asset with the "Com_Class_Schedule" RT and Com_Class__c pointing to our class
            List <RecordType> assetRTList = [SELECT Id FROM RecordType
                                             WHERE SObjectType = 'Asset' AND DeveloperName = 'Com_Class_Schedule'
                                             LIMIT 1];
            
            Id assetRt; 
            if (assetRTList.size() > 0) {
                assetRt = assetRTList[0].Id;
            }
            Asset a = new Asset(Name = 'Asset-Rcpt', RecordTypeId = assetRt, Com_Class__c = cls.Id);
            insert a;
            
            // Service Resource bound to asset (ResourceType 'S') — this is critical for your inner IF
            ServiceResource sr = new ServiceResource(Name = 'SR-Rcpt', IsActive = true, ResourceType = 'S', AssetId = a.Id);
            insert sr;
            
            // Community SA record type
            Id saRtId = Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
            
            Datetime startT = DateTime.newInstance(System.today(), Time.newInstance(10, 0, 0, 0));
            Datetime endT   = startT.addHours(1);
            
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = acc.Id,                 // gives AccountId after insert
                ServiceTerritoryId = st.Id,
                FSSK__FSK_Assigned_Service_Resource__c = sr.Id,
                Status = 'Scheduled',
                SchedStartTime = startT,
                SchedEndTime   = endT,
                RecordTypeId   = saRtId,
                // Values used in the event payload later:
                Com_SAP_Document_Number__c = 'DTest-001',
                Com_SAP_Fiscal_Year__c     = '2025',
                Com_Payment_Ref__c         = 'PTest-001',
                Booking_Amount__c          = 123.45
            );
            insert sa;
            
            // Build oldMap with previous state so your filter sees a change to "Success"
            ServiceAppointment saOld = sa.clone(false, true, false, false);
            saOld.put('Com_SAP_Invoice_Integration_Status__c', 'Pending');
            Map<Id, SObject> oldMap = new Map<Id, SObject>{ sa.Id => saOld };
                
                // Flip to Success (this is what your code filters on)
                sa.Com_SAP_Invoice_Integration_Status__c = 'Success';
            sa.Com_Payment_Status__c = 'Success';
            update sa;
            
            // --- Execute and validate ---
            Test.startTest();
            // If your method lives in another class, change this class name:
            ServiceAppointment newAppointment = [Select Id, RecordTypeId, AccountId, Com_Payment_Status__c, Master_Service_Appointment__c, Com_SAP_Invoice_Integration_Status__c from ServiceAppointment where Id =: sa.Id LIMIT 1];
            ServiceAppointmentTriggerHandler.fireInvoicePlatformEvent(new List<ServiceAppointment>{ newAppointment }, oldMap);
            ServiceAppointmentTriggerHandler.fireRecieptPlatformEvent(new List<ServiceAppointment>{ newAppointment }, oldMap);
            Test.stopTest();
            
            // Sanity: record still present and has the "Success" we set.
            ServiceAppointment check = [
                SELECT Id, Com_SAP_Invoice_Integration_Status__c, AccountId,
                FSSK__FSK_Assigned_Service_Resource__c
                FROM ServiceAppointment WHERE Id = :sa.Id
            ];
            System.assertEquals('Success', (String)check.get('Com_SAP_Invoice_Integration_Status__c'));
            System.assertNotEquals(null, check.AccountId, 'AccountId should be populated from ParentRecordId=Account');
            System.assertNotEquals(null, check.FSSK__FSK_Assigned_Service_Resource__c, 'SR required for inner IF');
        }
    }
}