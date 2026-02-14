@isTest
public class UnitAssignmentTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){

    /*    User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager.IsActive = TRUE;
        insert salesManager;
  */
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
      
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        // Account acc = TestObjectsFactory.getPersonAccountRecord();
        // insert acc;
     /*   Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.SourceofFunds__pc = 'Employment Income';
        acc.Company__pc = 'AbuDhabi investment Authority';
        acc.Position__pc = 'Manager';
        acc.CompanyAddress__pc = 'AbuDhabi investment 211 corniche AD';
        acc.AnnualIncome__pc = 130000;
        acc.NoofYearswithCompany__pc = 32;
        acc.Industry = 'Government';
        acc.CustomerBankName__c = 'Abhu Dhabi';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        acc.EmploymentStatus__pc  = 'Employed';
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;*/
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Project__c = project.id;
        insert unit;

        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.id;
        unit2.Status__c = 'New';
//        unit2.AssignedToUser__c = salesManager.Id;
        insert unit2;

        Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        unit3.Project__c = project.id;
        unit3.Status__c = 'New';
//        unit3.AssignedToUser__c = salesManager.Id;
        insert unit3;

        Unit__c unit4 = TestObjectsFactory.unitDataSetup('25086');
        unit4.Project__c = project.id;
        unit4.Status__c = 'New';
        insert unit4;
    }

     @IsTest
    static void testAssignment1(){
        Unit__c un1 = [SELECT Id FROM Unit__C LIMIT 1];
        User usr = TestObjectsFactory.getUserRecord('Sales Admin','srana');
        usr.ManagerId = UserInfo.getUserId();
        insert usr;
        Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
        unitAssingment.RequestedBy__c = usr.id;
        unitAssingment.Status__c = 'Pending approval';
        unitAssingment.Unit__c = un1.Id;
        unitAssingment.Approver__c = usr.Id;
        unitAssingment.RequestedDate__c = System.now();
       	Insert unitAssingment;
        List<Id> lstIds = new List<Id>{unitAssingment.Id};
       // UnitAssignmentTriggerHandler.updateApprovedUnitAssignments(lstIds);
       UnitAssignmentTriggerHandler.getFieldLabel('Unit_Assignment__c','Status__c');
        unitAssingment.Status__c = 'Approved';
        TriggerHandler.processedIds = new Set<Id>();
        try{
            Update unitAssingment; 
        }catch(Exception e){
            
        }
    }
    
   /* @IsTest
    static void testUAInsertOne(){
        
        Test.startTest();
        try {
            User salesManager1 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
            salesManager1.IsActive = TRUE;
            insert salesManager1;
            User salesManager2 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM2');
            salesManager2.IsActive = TRUE;
            salesManager2.ManagerId = salesManager1.Id;
            insert salesManager2;
            List<Unit__c> lstUnits = [SELECT Id FROM Unit__c LIMIT 1];
            Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
            unitAssingment.RequestedBy__c = salesManager2.Id;
            unitAssingment.Status__c = 'Pending approval';
            unitAssingment.Unit__c = lstUnits[0].Id;
            unitAssingment.Approver__c = salesManager2.ManagerId;
            unitAssingment.RequestedDate__c = System.now();
            TriggerHandler.processedIds = new Set<Id>();
            insert unitAssingment;
            List<Id> uaId = new List<Id>();
            uaId.add(unitAssingment.Id);           
        } catch (Exception ex) {
            System.debug('Test');    
        }
        Test.stopTest();        
    }

    @IsTest
    static void testUAInsertTwo(){
        User salesManager1 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager1.IsActive = TRUE;
        insert salesManager1;
        User salesManager2 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM2');
        salesManager2.IsActive = TRUE;
        salesManager2.ManagerId = salesManager1.Id;
        insert salesManager2;
        Test.startTest();
        try {
            Unit__c tempRec = [SELECT Id FROM Unit__c LIMIT 1];
            Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
            unitAssingment.RequestedBy__c = salesManager2.Id;
            unitAssingment.Status__c = 'Pending approval';
            unitAssingment.Unit__c = tempRec.Id;
            unitAssingment.Approver__c = salesManager2.ManagerId;
            unitAssingment.RequestedDate__c = System.now();
            insert unitAssingment;
            Unit_Assignment__c unitAssingment1 = new Unit_Assignment__c();
            unitAssingment1.RequestedBy__c = salesManager2.Id;
            unitAssingment1.Status__c = 'Pending approval';
            unitAssingment1.Unit__c = tempRec.Id;
            unitAssingment1.Approver__c = salesManager2.ManagerId;
            unitAssingment1.RequestedDate__c = System.now();
            TriggerHandler.processedIds = new Set<Id>();
            insert unitAssingment1;
        } catch (Exception ex) {
            System.debug('test');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testUAUpdateTwo(){
        
        Test.startTest();
        try {
            User userDetail = Utilities.getLoggedInUserDetail();
            User salesManager1 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
            salesManager1.IsActive = TRUE;
            insert salesManager1;
            User salesManager2 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM2');
            salesManager2.IsActive = TRUE;
            salesManager2.ManagerId = salesManager1.Id;
            insert salesManager2;
            User salesManager3 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM3');
            salesManager3.IsActive = TRUE;
            salesManager3.ManagerId = salesManager1.Id;
            insert salesManager3;
            List<Unit__c> lstUnits = [SELECT Id FROM Unit__c WHERE AssignedToUser__c = null LIMIT 2];
            Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
            unitAssingment.RequestedBy__c = salesManager2.Id;
            unitAssingment.Status__c = 'Pending approval';
            unitAssingment.Unit__c = lstUnits[0].Id;
            unitAssingment.Approver__c = salesManager2.ManagerId;
            unitAssingment.RequestedDate__c = System.now();
            TriggerHandler.processedIds = new Set<Id>();
            insert unitAssingment;
            List<Id> uaId = new List<Id>();
            uaId.add(unitAssingment.Id);
            Unit_Assignment__c unitAssingment1 = new Unit_Assignment__c();
            unitAssingment1.RequestedBy__c = salesManager2.Id;
            unitAssingment1.Status__c = 'Pending approval';
            unitAssingment1.Unit__c = lstUnits[1].Id;
            unitAssingment1.Approver__c = salesManager2.ManagerId;
            unitAssingment1.RequestedDate__c = System.now();
            TriggerHandler.processedIds = new Set<Id>();
            insert unitAssingment1;
            List<Unit_Assignment__c> lstUAold = new List<Unit_Assignment__c>();
            lstUAold.add(unitAssingment1);
            lstUAold.add(unitAssingment);
            List<Unit_Assignment__c> lstUA = new List<Unit_Assignment__c>();
            unitAssingment1.ApproverResponse__c = 'Approved';
            unitAssingment1.Status__c = 'Approved';
            lstUA.add(unitAssingment1);
            unitAssingment.ApproverResponse__c = 'Approved';
            unitAssingment.Status__c = 'Approved';
            lstUA.add(unitAssingment);
            TriggerHandler.processedIds = new Set<Id>();
            update lstUA;
            unitAssingment.ApproverResponse__c = 'Rejected';
            unitAssingment.Status__c = 'Rejected';
            TriggerHandler.processedIds = new Set<Id>();
            update lstUA;
        } catch (Exception ex) {
            System.debug('Test');    
        }
        Test.stopTest();        
    }

    @IsTest
    static void testUAupdateOne(){
        
        Test.startTest();
            List<User> lstUser = new List<User>();
            User salesManager1 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
            salesManager1.IsActive = TRUE;
            lstUser.add(salesManager1);
            User salesManager2 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM2');
            salesManager2.IsActive = TRUE;
            salesManager2.ManagerId = salesManager1.Id;
            lstUser.add(salesManager2);
            User salesManager3 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM3');
            salesManager3.IsActive = TRUE;
            salesManager3.ManagerId = salesManager1.Id;
            lstUser.add(salesManager3);
            User salesManager4 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM4');
            salesManager4.IsActive = TRUE;
            salesManager4.ManagerId = salesManager1.Id;
            lstUser.add(salesManager4);
            insert lstUser; 
            List<Unit_Assignment__c> lstUA = new List<Unit_Assignment__c>();
            List<Unit__c> lstUnits = [SELECT Id,AssignedToUser__c, Status__c  FROM Unit__c LIMIT 2];
            System.debug('lstUnits' + lstUnits);
            Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
            unitAssingment.RequestedBy__c = salesManager2.Id;
            unitAssingment.Status__c = 'Pending approval';
            unitAssingment.Unit__c = lstUnits[0].Id;
            unitAssingment.Approver__c = salesManager2.ManagerId;
            unitAssingment.RequestedDate__c = System.now();
            lstUA.add(unitAssingment);

            Unit_Assignment__c unitAssingment1 = new Unit_Assignment__c();
            unitAssingment1.RequestedBy__c = salesManager3.Id;
            unitAssingment1.Status__c = 'Pending approval';
            unitAssingment1.Unit__c = lstUnits[1].Id;
            unitAssingment1.Approver__c = salesManager3.ManagerId;
            unitAssingment1.RequestedDate__c = System.now();
            lstUA.add(unitAssingment1);
            try {
                TriggerHandler.processedIds = new Set<Id>();
                insert lstUA;
            } catch (Exception ex) {
                System.debug('Inser Exception' + lstUA);
            }
            // lstUA.clear();
            unitAssingment1.ApproverResponse__c = 'Approved';
            unitAssingment1.Status__c = 'Approved';
            // lstUA.add(unitAssingment1);
            unitAssingment.ApproverResponse__c = 'Approved';
            unitAssingment.Status__c = 'Approved';
        try{
            TriggerHandler.processedIds = new Set<Id>();
            update lstUA;
        } catch (Exception ex) {
            System.debug('Test');    
        }
        Test.stopTest();        
    }

    @IsTest
    static void testUAupdateThree(){        
        Test.startTest();
        List<User> lstUser = new List<User>();
        User salesManager1 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager1.IsActive = TRUE;
        lstUser.add(salesManager1);
        User salesManager2 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM2');
        salesManager2.IsActive = TRUE;
        salesManager2.ManagerId = salesManager1.Id;
        lstUser.add(salesManager2);
        User salesManager3 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM3');
        salesManager3.IsActive = TRUE;
        salesManager3.ManagerId = salesManager1.Id;
        lstUser.add(salesManager3);
        User salesManager4 = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM4');
        salesManager4.IsActive = TRUE;
        salesManager4.ManagerId = salesManager1.Id;
        lstUser.add(salesManager4);
        insert lstUser; 
        List<Unit_Assignment__c> lstUA = new List<Unit_Assignment__c>();
        List<Unit__c> lstUnits = [SELECT Id,AssignedToUser__c, Status__c  FROM Unit__c LIMIT 4];
        System.debug('lstUnits' + lstUnits);
        Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
        unitAssingment.RequestedBy__c = salesManager2.Id;
        unitAssingment.Status__c = 'Pending approval';
        unitAssingment.Unit__c = lstUnits[0].Id;
        unitAssingment.Approver__c = salesManager2.ManagerId;
        unitAssingment.RequestedDate__c = System.now();
        lstUA.add(unitAssingment);

        Unit_Assignment__c unitAssingment1 = new Unit_Assignment__c();
        unitAssingment1.RequestedBy__c = salesManager3.Id;
        unitAssingment1.Status__c = 'Pending approval';
        unitAssingment1.Unit__c = lstUnits[1].Id;
        unitAssingment1.Approver__c = salesManager3.ManagerId;
        unitAssingment1.RequestedDate__c = System.now();
        lstUA.add(unitAssingment1);

        Unit_Assignment__c unitAssingment2 = new Unit_Assignment__c();
        unitAssingment2.RequestedBy__c = salesManager4.Id;
        unitAssingment2.Status__c = 'Pending approval';
        unitAssingment2.Unit__c = lstUnits[2].Id;
        unitAssingment2.Approver__c = salesManager4.ManagerId;
        unitAssingment2.RequestedDate__c = System.now();
        lstUA.add(unitAssingment2);

        Unit_Assignment__c unitAssingment3 = new Unit_Assignment__c();
        unitAssingment3.RequestedBy__c = salesManager4.Id;
        unitAssingment3.Status__c = 'Pending approval';
        unitAssingment3.Unit__c = lstUnits[3].Id;
        unitAssingment3.Approver__c = salesManager4.ManagerId;
        unitAssingment3.RequestedDate__c = System.now();
        lstUA.add(unitAssingment3);
        try {
            TriggerHandler.processedIds = new Set<Id>();
            insert lstUA;
        } catch (Exception ex) {
            System.debug('Inser Exception' + lstUA);
        }
        lstUA.clear();
        unitAssingment.ApproverResponse__c = 'Approved';
        unitAssingment.Status__c = 'Approved';
        lstUA.add(unitAssingment);
        unitAssingment2.ApproverResponse__c = 'Approved';
        unitAssingment2.Status__c = 'Approved';
        lstUA.add(unitAssingment2);
        try{
            TriggerHandler.processedIds = new Set<Id>();
            UnitAssignmentTriggerHandler.getFieldLabel('Unit__c', 'Status__c');
            update lstUA;
        } catch (Exception ex) {
            System.debug('Test');    
        }
        lstUA.clear();
        unitAssingment1.ApproverResponse__c = 'Approved';
        unitAssingment1.Status__c = 'Approved';
        lstUA.add(unitAssingment1);
        unitAssingment3.ApproverResponse__c = 'Approved';
        unitAssingment3.Status__c = 'Approved';
        lstUA.add(unitAssingment3);
        try{
            TriggerHandler.processedIds = new Set<Id>();
            update lstUA;
        } catch (Exception ex) {
            System.debug('Test');    
        }
        Test.stopTest();        
    }*/
}