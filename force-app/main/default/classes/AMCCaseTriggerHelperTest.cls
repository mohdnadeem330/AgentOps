/*
*********************************************************
Apex Class Name    : AMCCaseTriggerHelperTest
Created Date       : 
@description       : Class to test AMCCaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class AMCCaseTriggerHelperTest {
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
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.OwnerManagerEmail__c = 'test@gmail.com';
        newAccount.OwnerManagerEmail__pc = 'test1@gmail.com';
        AccountTriggerHandler.skipAccountTrigger = true;
        insert newAccount;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc;   
        AccountTriggerHandler.skipAccountTrigger = false;
    }
    @isTest
    public static void amcCaseTriggerHelperTest() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
		Id amcRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('AMC').getRecordTypeId();        
        Case amcCase = TestObjectsFactory.getCaseRecord(amcRT, Constants.PAYMENT_EXTENSION_TYPE, unit[0].Id, 'Walk-In');
        amcCase.Subject='Test Subject';
        amcCase.Status = 'New';
        amcCase.CaseCategory__c = 'On Demand';
        Test.StartTest();
        insert amcCase;  
        List<Case> casUpdList = new List<Case>();
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> amcCaseList = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Id =:amcCase.id];
        amcCaseList[0].Status = 'Closed';
        amcCaseList[0].AMC_Closure_Reason__c = 'Completed Sucessfully';
        update amcCaseList[0];
        List<Case> amcCaseList1 = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Id =:amcCase.id];
        amcCaseList1[0].Status = 'Resolved';
        update amcCaseList1[0];
        Test.StopTest();
    }
}