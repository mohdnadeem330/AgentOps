/*
*********************************************************
Apex Class Name    : HomeFinanceCaseTriggerHelperTest
Created Date       : 
@description       : Class to test HomeFinanceCaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class HomeFinanceCaseTriggerHelperTest {

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
    public static void homeFinanceCaseTriggerHelperTest() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
		Id homeFinRT =Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();        
        Case homeFinCase = TestObjectsFactory.getCaseRecord(homeFinRT, 'Question', unit[0].Id, 'Walk-In');
        homeFinCase.Status = 'New';
        insert homeFinCase;
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> homeFinCaseList = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Id =:homeFinCase.id];
        homeFinCaseList[0].Verified_by_Finance__c = true;
        homeFinCaseList[0].Sum_of_Total_Commission_for_Aldar__c = 10000;
        homeFinCaseList[0].PaymentReceived__c = true;
        update homeFinCaseList[0];
    }
}