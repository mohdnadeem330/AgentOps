@isTest
public class CreateUpdateUnitAssignmentTest {
    @TestSetup
    static void makeData(){

        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        insert unit2;
        
        Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        insert unit3;

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaysthakurSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.ReferralType__c = Constants.OPPORTUINTY_REFERRAL_STAFF;
        insert opp;
        
        Unit_Assignment__c invalidAssignment = new Unit_Assignment__c(
            Unit__c = unit1.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment;
        
    }

    /*@IsTest
    static void doPost(){
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25055');
        insert unit1;

        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        User sm = [SELECT Id FROM User WHERE ManagerId != null LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ u.Id }, opp.Id);

        Test.stopTest();

    }*/
    
    @IsTest
    static void doPost1(){
        
		Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        insert unit2;
        List<Unit__c> u = [SELECT Id FROM Unit__c LIMIT 2];
        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
         Unit_Assignment__c invalidAssignment1 = new Unit_Assignment__c(
            Unit__c = unit2.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
             approver__c = smManager.Id
        );
        insert invalidAssignment1;

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ u[0].Id }, opp.Id);

        Test.stopTest();

    }
    
    @IsTest
    static void doPost2(){

        list<Unit__c> u = [SELECT Id FROM Unit__c LIMIT 3];
        User sm = [SELECT Id FROM User WHERE ManagerId != null LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ u[0].Id,u[1].Id,u[2].Id }, opp.Id);

        Test.stopTest();
    }
    
    @IsTest
    static void doPost3(){
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Status__c = 'In-progress';
        insert unit2;

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
        Unit_Assignment__c invalidAssignment1 = new Unit_Assignment__c(
            Unit__c = unit2.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment1;

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ unit2.Id }, opp.Id);
        
        
        

        Test.stopTest();
    }
    
     @IsTest
    static void doPost4(){
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Status__c = 'Available';
        unit2.AssignedToUser__c=null;
        insert unit2;

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
        Unit_Assignment__c invalidAssignment1 = new Unit_Assignment__c(
            Unit__c = unit2.Id,
            Status__c = 'Pending approval', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment1;

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ unit2.Id }, opp.Id);
        
        
        

        Test.stopTest();
    }
    @IsTest
    static void doPost5(){
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Status__c = 'Available';
        unit2.AssignedToUser__c=null;
        insert unit2;

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
         Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        unit3.Status__c = 'Available';
        unit3.AssignedToUser__c=null;
        insert unit3;
        
        Unit_Assignment__c invalidAssignment1 = new Unit_Assignment__c(
            Unit__c = unit2.Id,
            Status__c = 'Pending approval', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment1;

        Unit_Assignment__c invalidAssignment2 = new Unit_Assignment__c(
            Unit__c = unit3.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment2;
        
        List<Unit__c> u = [SELECT Id FROM Unit__c WHERE name ='25085'];

        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(userInfo.getUserId(), new List<Id>{ unit2.Id,unit3.Id }, opp.Id);   

        Test.stopTest();
    }
    
    @IsTest
    static void doPost6(){

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
         Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        unit3.Status__c = 'Available';
        unit3.AssignedToUser__c=null;
        insert unit3;
        

        Unit_Assignment__c invalidAssignment2 = new Unit_Assignment__c(
            Unit__c = unit3.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment2;
        
        List<unit__c> units = [select id,AssignedToUser__c from Unit__c];
         List<unit__c> unitToBeAssigned = new List<unit__c>();
        for(Unit__C u : units) {
            u.AssignedToUser__c = sm.Id;
            unitToBeAssigned.add(u);
        }
        update unitToBeAssigned;


        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(userInfo.getUserId(), new List<Id>{ unit3.Id }, opp.Id);   

        Test.stopTest();
    }
     @IsTest
    static void doPost7(){

        User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
        Unit__c unit4 = TestObjectsFactory.unitDataSetup('25086');
        unit4.Status__c = 'Available';
        unit4.AssignedToUser__c=null;
        insert unit4;
        
        Unit_Assignment__c invalidAssignment3 = new Unit_Assignment__c(
            Unit__c = unit4.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert invalidAssignment3;
        
        List<unit__c> units = [select id,AssignedToUser__c from Unit__c];
         List<unit__c> unitToBeAssigned = new List<unit__c>();
        for(Unit__C u : units) {
            u.AssignedToUser__c = sm.Id;
            unitToBeAssigned.add(u);
        }
        update unitToBeAssigned;


        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(sm.Id, '/unitAssignments');

        CreateUpdateUnitAssignmentWebService.doPost(sm.Id, new List<Id>{ unit4.Id }, opp.Id);   

        Test.stopTest();
    }
}