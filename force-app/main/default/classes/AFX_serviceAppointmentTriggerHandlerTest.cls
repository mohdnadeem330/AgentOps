/*
* Class Name:  AFX_serviceAppointmentTriggerHandlerTest
* Created By : R3-DLP implementation-Smaartt
* Description: Test class used for handling Service appoinement actions
*/
@istest 

public class AFX_serviceAppointmentTriggerHandlerTest {
    @isTest
    Public static void testServiceAppointmentCreationChild() {
        FSL.GlobalAPIS.addStatusTransition('New', 'Closed');
       // FSL.GlobalAPIS.addStatusTransition(fromStatus, toStatus);
        Account testAccount = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        testAccount.MobileNumber__c = '123456789';
        insert testAccount;   
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case caseObj = new Case();
        caseObj.AccountId = testAccount.id;
        caseObj.RecordtypeId = recordTypeId;
        caseObj.Status = 'New';
        caseObj.Subject = 'Test Case';
        insert caseObj;
        
        WorkType wt = new WorkType();
        wt.Name = 'Technician';        
        wt.EstimatedDuration = 1;
        insert wt;
        
        WorkType wt1 = new WorkType();
        wt1.Name = 'DLP Executive';        
        wt1.EstimatedDuration = 1;
        insert wt1;
        
        WorkType wt2 = new WorkType();
        wt2.Name = 'Contractor DLP';        
        wt2.EstimatedDuration = 1;
        insert wt2;
        
        WorkOrder woObj = new WorkOrder();
        woObj.CaseId = caseObj.Id;
        woObj.AccountId = testAccount.Id;
        woObj.WorkTypeId =  wt1.Id;
        woObj.Status = 'New';
        insert woObj;
       // WorkOrderLineItem testWOL = new WorkOrderLineItem(WorkOrder = woObj,WorkTypeId = wt.Id);
       // WorkOrderLineItem testWOL2 = new WorkOrderLineItem(WorkOrder = woObj,WorkTypeId = wt1.Id);
       // insert testWOL;
        //insert testWOL2;
       
        //List<WorkOrderLineItem> woli = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :woObj.Id];
       // List<WorkOrderLineItem> woli = [SELECT Id FROM WorkOrderLineItem WHERE WorkType.Name = 'Plumber'];
       
       
        
       FSL__Scheduling_Policy__c scpolicy = New FSL__Scheduling_Policy__c();
       scpolicy.Name = 'Aldar Scheduling Policy';
       insert scpolicy;       
  
        Id assessmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId();
        ServiceAppointment testSA = new ServiceAppointment();
        testSA.Case__c = caseObj.Id;
        //testSA.ParentRecordType= 'WorkOrderLineItem';
        testSA.ParentRecordId =  woObj.Id;
      
        testSA.Case__c = caseObj.Id; 
        testSA.RecordTypeId = assessmentRecordTypeId ; 
        
        testSA.EarliestStartTime = system.today(); 
        Insert testSA;
        Test.startTest();  
        testSA.SchedStartTime = system.today();        
        testSA.Status = 'Assigned';
        testSA.AccountEmailID__c = 'test@test.com'; 
        testSA.SchedEndTime = system.today()+1; 
        testSA.OwnerId  = UserInfo.getUserId();
        
        testSA.Status = 'En Route';  
        
        testSA.Status = 'Work In Progress'; 
        testSA.Quick_Fix__c=false;  
        
        //Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId();               
        testSA.Status = 'Closed';
       // testSA.StatusCategory = 'Completed';
        testSA.OwnerId = Userinfo.getUserId();
        
        testSA.Closed_Reason__c='Completed Succeessfully';
        Update  testSA  ; 
        
      
        
        ServiceAppointment assSA = new ServiceAppointment();
        //testSA.ParentRecordType= 'WorkOrderLineItem';
        assSA.ParentRecordId =  woObj.Id;
      
        assSA.Case__c = caseObj.Id; 
        assSA.RecordTypeId = assessmentRecordTypeId ; 
        
        assSA.EarliestStartTime = system.today(); 
        Insert assSA;
        assSA.SchedStartTime = system.today();        
        assSA.Status = 'Scheduled';
        assSA.AccountEmailID__c = 'test@test.com'; 
        assSA.SchedEndTime = system.today()+1; 
        //Update  assSA  ; 
        assSA.Status = 'En Route';  
        //Update assSA ; 
        assSA.Status = 'Work In Progress'; 
        //Update assSA ; 
        assSA.OwnerId  = UserInfo.getUserId();
        assSA.Status = 'Closed';
        assSA.Closed_Reason__c='Partially Completed';
        Update  assSA  ;                              
         
        WorkType wtp = new WorkType();
        wtp.Name = 'Plumber';        
        wtp.EstimatedDuration = 1;
        insert wtp;
        
        WorkOrderLineItem woli1 = New WorkOrderLineItem();
        woli1.Status = 'New';
        woli1.WorkTypeId = wt2.Id;
        woli1.WorkOrderId = woObj.Id; 
        woli1.Case__c = caseObj.Id; 
        insert woli1;
        
        ServiceAppointment confSA = new ServiceAppointment();
        confSA.ParentRecordId =  woli1.Id;
      
        confSA.Case__c = caseObj.Id; 
        confSA.RecordTypeId = assessmentRecordTypeId ; 
        confSA.EarliestStartTime = system.today(); 
        Insert confSA;
        confSA.SchedStartTime = system.today();        
        confSA.Status = 'Scheduled';
        confSA.AccountEmailID__c = 'test@test.com'; 
        confSA.SchedEndTime = system.today()+1;       
         
         confSA.Status = 'Closed';
         assSA.OwnerId  = UserInfo.getUserId();
         confSA.Closed_Reason__c='Partially Completed';
        Update confSA ;
        Test.stopTest();
       
          
        List<ServiceAppointment> listsa = new  List<ServiceAppointment>();
        listsa.add(testSA);
        listsa.add(confSA);
        listsa.add(assSA);
        AFX_serviceAppointmentTriggerHandler.serviceAppointmentCreationChild(listsa);
        
        AFX_serviceAppointmentTriggerHandler.serviceAppointmentCreation(listsa);
        
        
    }
   }