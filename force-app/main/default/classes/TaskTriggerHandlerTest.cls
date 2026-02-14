@isTest
public class TaskTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        insert salesManager;
    }
    
    @isTest()
    static void createTaskWithCaseTest() {
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Requests').getRecordTypeId();
        newCase.Origin = 'Phone';
        /*newCase.CustomerType__c = 'Owner';
        newCase.CaseCategory__c = 'Contact Center';
        newCase.SubCategory__c = 'Customer Feedback';*/
        newCase.CaseCategory__c = 'DM Finance';
        newCase.SubCategory__c = 'Direct Debit Form Services';
        insert newCase;
        User salesManager = [SELECT Id FROM User WHERE profile.Name =: Constants.SALES_MANAGER LIMIT 1];
        newCase.Assigned_To__c = salesManager.id;
        newCase.status = 'Work In Progress';
        update newCase;
        
        Test.startTest();
        Task casetask =new Task();
        casetask.Subject='Call';
        casetask.Status = 'Completed';
        casetask.Description = 'Case Task Description';
        casetask.WhatId = newCase.id;
        insert casetask;
        Test.stopTest();

    }
        
    @isTest()
    static void createTaskTest() {

        Test.startTest();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
         /*added by Dharanesh*/
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PersonEmail = 'Henry.Wong1@gmail.com';
        insert acc;
        
        /*added by Dharanesh*/

		User salesManager = [SELECT Id FROM User WHERE profile.Name =: Constants.SALES_MANAGER LIMIT 1];
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        //leadRec.Status = '';
        insert leadRec;

        leadRec.OwnerId = salesManager.Id;
        update leadRec;
        
        Task task = TestObjectsFactory.getLeadActivity(leadRec.Id);

        RoundRobinAssignmentMatrix__c rr = new RoundRobinAssignmentMatrix__c();
        rr.User__c = salesManager.Id;
        rr.Status__c = 'Available';
        rr.CurrentLoad__c = 0;
        rr.AgentThreshold__c = 20;
        insert rr;

        TriggerHandler.processedIds = new Set<Id>();
        task.Subject = Constants.TASK_DAY1;
        task.CustomerResponse__c = Constants.CUSTOMER_REACHED;
        task.TaskNumber__c = 9;
        task.OwnerId = salesManager.Id;
         try {
            
            update task;
            
        } catch (DmlException e) {
            
           // System.assert(e.getMessage().contains('There is existing account with same email, please verify lead to proceed.'),
                       //   'Unexpected error message: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest()
    static void testCaseLogChanges1() {
        // Create dummy RecordType IDs
        Id queriesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Queries').getRecordTypeId();
        Id complaintsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaints').getRecordTypeId();
        Id requestsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();

        // Create test cases
        List<Case> testCases = new List<Case>{
            new Case(
                CaseCategory__c = 'DM Finance',
        		SubCategory__c = 'Direct Debit Form Services',
                Subject = 'Test Case 1',
                Status = Constants.CASE_NEW,
                RecordTypeId = queriesRecordTypeId
            ),
            new Case(
                CaseCategory__c = 'DM Finance',
        		SubCategory__c = 'Direct Debit Form Services',
                Subject = 'Test Case 2',
                Status = Constants.CASE_WORK_IN_PROGRESS,
                RecordTypeId = complaintsRecordTypeId,
                Customer_Follow_up_Count__c = 2
            ),
            new Case(
                CaseCategory__c = 'DM Finance',
        		SubCategory__c = 'Direct Debit Form Services',
                Subject = 'Test Case 3',
                Status = 'Closed',
                RecordTypeId = requestsRecordTypeId
            )
        };
        insert testCases;

        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        // Create Task records (new and old)
        Task oldTask = new Task(
            Subject = 'Call - Follow up by customer',
            OwnerId = u.Id,
            WhoId = testCases[0].Id,
            Description = 'test',
            CustomerResponse__c = 'Customer Not Reachable'
        );

        // Call the method
        TaskTriggerHandler.caseLogChanges(
            new List<Id>{testCases[0].Id, testCases[1].Id, testCases[2].Id},
            queriesRecordTypeId,
            complaintsRecordTypeId,
            requestsRecordTypeId
        );

        // Fetch updated cases
        List<Case> updatedCases = [SELECT Id, Customer_Follow_up_Count__c, Last_activity__c, Sub_Status__c FROM Case WHERE Id IN :testCases];

        
    }
}