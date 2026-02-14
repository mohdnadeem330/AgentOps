/*
*********************************************************
Apex Class Name    : CustomerServiceCaseTriggerHelperTest
Created Date       : 
@description       : Class to test CustomerServiceCaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
//dummy commit
@isTest
public class CustomerServiceCaseTriggerHelperTest {
    @testSetup
    public static void createData(){ 
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.OwnerManagerEmail__c = 'test@gmail.com';
        newAccount.OwnerManagerEmail__pc = 'test1@gmail.com';
        AccountTriggerHandler.skipAccountTrigger = true;
        insert newAccount;
        AccountTriggerHandler.skipAccountTrigger = false;
    }
    @isTest
    public static void customerServiceCaseInsert() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        List<Case> reqCaseList = new List<Case>();
        Id requestRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();        
        Case reqCase = TestObjectsFactory.getCaseRecord(requestRT, 'Question', unit[0].Id, 'Email');
        reqCase.Subject='Test Subject';
        reqCase.Status = 'New';
        reqCase.SubCategory__c = 'Requests for extra GFA';
        reqCase.CaseCategory__c = 'Property Handover';
        reqCase.Priority = 'P1';
        reqCaseList.add(reqCase);
        Case reqCase1 = TestObjectsFactory.getCaseRecord(requestRT, 'Question', unit[0].Id, 'Email');
        reqCase1.Subject='Test Subject';
        reqCase1.Status = 'New';
        reqCase1.SubCategory__c = 'Requests for extra GFA';
        reqCase1.CaseCategory__c = 'Property Handover';
        reqCase1.Priority = 'P2';
        reqCaseList.add(reqCase1);        
        Id queriesRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Queries').getRecordTypeId();        
        Case queCase = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit[0].Id, 'Walk-In');
        queCase.Subject='Test Subject';
        queCase.Status = 'New';
        queCase.SubCategory__c = 'Requests for extra GFA';
        reqCaseList.add(queCase);
        Test.StartTest();
            insert reqCaseList;
        Test.StopTest();
        
    }
    @isTest
    public static void customerServiceCaseUpdate() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold']; 
        List<Case> reqCaseList = new List<Case>();
        Id requestRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();
        Case reqCase2 = TestObjectsFactory.getCaseRecord(requestRT, 'Question', unit[0].Id, 'Email');
        reqCase2.Subject='Test Subject';
        reqCase2.Status = 'Resolved';
        reqCase2.Assigned_To__c = null;
        reqCase2.SubCategory__c = 'Requests for extra GFA';
        reqCase2.Priority = 'P3';
        reqCaseList.add(reqCase2);
        Test.StartTest();
        insert reqCaseList;
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> reqCsList = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where id=:reqCase2.Id];
        reqCsList[0].FCR__c = false;
        reqCsList[0].Status = 'Resolved';
        reqCsList[0].Assigned_To__c = UserInfo.getUserId();
        reqCsList[0].Sub_Status__c = 'Email Sent';
        reqCsList[0].CaseCategory__c = 'Property Handover';        
        update reqCsList[0];        
        Test.StopTest();
    }
    @isTest
    public static void customerServiceCaseUpdate1() { 
        Test.StartTest();
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id recordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByName().get('DLP').getRecordTypeId();
        Account ac = [SELECT PersonContactId  FROM Account LIMIT 1];
        Case c = new Case(ContactId = ac.PersonContactId,Subject='Test DLP Subject',CustomerType__c='Owner',status = 'New',DLP_Closure_Reason__c = 'Attended',RecordTypeId=recordTypeId,Unit__c=unit[0].Id,Vertical__c='DLP',Origin='Phone',SubVertical__c='DLP',CaseCategory__c='Civil',SubCategory__c='Aluminium',ResolutionType__c='Replace',Skills_Required__c='Electrician',Single_DLP_slot__c=true);
        insert c;
        Id requestRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> dlpCase = [Select id,Origin,RecordTypeId,Subject,Status,Location__c,OwnerId,Ownership_Bulk_Changed__c,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Subject = 'Test DLP Subject'];
        dlpCase[0].Origin = 'Email';
        dlpCase[0].SubVertical__c = null;
        dlpCase[0].CaseCategory__c = 'CMO';
        dlpCase[0].RecordTypeId = requestRT;
        dlpCase[0].Ownership_Bulk_Changed__c = true;
        dlpCase[0].Location__c = 'Al Raha';
        dlpCase[0].OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1][0].Id;
        update dlpCase[0];
        Test.StopTest();//Dummy Commit
    }
}