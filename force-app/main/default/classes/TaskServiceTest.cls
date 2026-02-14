@isTest
public class TaskServiceTest {
    
    @isTest static void callMethods() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;

        List<Opportunity> oppToInsert = new List<Opportunity>();

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Task task = TestObjectsFactory.getOpportunityActivity(opp.Id);

        TaskService.newTaskRecord(new List<Task> {task});
        TaskService.fetchTaskForAPIByUser(UserInfo.getUserId());

        Task task1 = TestObjectsFactory.getAccountActivity(acc.Id);
        TaskService.fetchTasksByAccountId(acc.Id);
        TaskService.getCustomerReachedTasks(new Set<Id>{acc.Id});
        TaskService.getTasksHaveCustomerResponse(new Set<Id>{acc.Id});
        TaskService.getTasksNumberOneRecords(new Set<Id>{acc.Id});
        TaskService.getActivitiesForCurrentUser(null);
        TaskService.fetchActivities('WhatId != null');

        try {
            TaskService.fetchActivities('Exception test');
        } catch (Exception e) {
            
        }
        TaskService.getStatusPicklistValues();
        TaskService.getPicklistValues();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        insert leadRec;

        TaskService.getLeadRecord(leadRec.Id);
        TaskService.getCustomerResponsePicklistValues();        

        Test.stopTest();
    }
}