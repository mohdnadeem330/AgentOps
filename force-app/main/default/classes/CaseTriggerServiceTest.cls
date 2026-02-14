/*
*********************************************************
Apex Class Name    : CaseTriggerServiceTest
Created Date       : 
@description       : Class to test CaseTriggerService
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class CaseTriggerServiceTest {
	@testSetup
    public static void createData(){ 
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; // Adjust profile name as needed
        User testUser = new User(
            ProfileId = profile.Id,
            LastName = 'Test',
            FirstName = 'User',
            Email = 'test@aldar.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert testUser;
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
        insert newAccount;        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        List<Case> casList = new List<Case>();
        Id dlpRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case dlpCs = TestObjectsFactory.getCaseRecord(dlpRecId, 'Question', unit.Id, 'Email');
        dlpCs.Subject='Test Subject';        
        dlpCs.Status = 'New';        
        dlpCs.Single_DLP_slot__c = true;
        casList.add(dlpCs);        
        insert casList;
    }
     @isTest
    public static void callCAFMCase_Test() {
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Id cafmRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_CAFM').getRecordTypeId();
        Case cafmCase = TestObjectsFactory.getCaseRecord(cafmRecId, 'Question', unit.Id, 'Email');
        cafmCase.Subject='Test Subject';
        cafmCase.Status = 'New';
        Test.StartTest();
        	insert cafmCase;
        Test.StopTest();      
    }
    @isTest
    public static void taskCreationForCase_Test() {
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Id stRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case standCase = TestObjectsFactory.getCaseRecord(stRecId, 'Question', unit.Id, 'Email');
        standCase.Subject='Test StandardCase Subject';
        standCase.Status = 'New';
        standCase.SubVertical__c = system.label.Case_Subvertical_Onboarding;
        insert standCase;
        TriggerHandler.processedIds = new Set<Id>();
        Case dlpCase = [Select id,Status,OwnerId,Single_DLP_slot__c from case where Id =:standCase.id limit 1];
        dlpCase.Status = Constants.CASE_WORK_IN_PROGRESS;
        //dlpCase.SubVertical__c = 'AMC';
        //dlpCase.Vertical__c = Constants.DLP_SUB_VERTICAL;
        //dlpCase.AMC_Closure_Reason__c = System.Label.AMCClosureForComleted;
        dlpCase.OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1][0].Id;
        Test.Starttest();
        	update dlpCase;
        Test.Stoptest();
    }
    @isTest
    public static void sendServiceReport_Test() {
        Id dlpRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        TriggerHandler.processedIds = new Set<Id>();
        Case dlpCase = [Select id,Status,OwnerId,ContactId,Contact.Email,Single_DLP_slot__c from case where RecordTypeId =:dlpRecId limit 1];
        dlpCase.DLP_Closure_Reason__c = 'Unreachable';
        dlpCase.Status = 'Closed';
        Test.Starttest();
        	update dlpCase;
        Test.Stoptest();
    }
    @isTest
    public static void beforeUpdateEntitlementAndOwnerIdMapping_Test() {
        List<Case> csList = new List<Case>();
        List<Case> csListUpd = new List<Case>();
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
		Id homeFinRT =Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();        
        Case homeFinCase = TestObjectsFactory.getCaseRecord(homeFinRT, 'Question', unit[0].Id, 'Walk-In');
        homeFinCase.Status = 'New';
        csList.add(homeFinCase);        
        insert csList;
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> homeFinCaseList = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Id =:homeFinCase.id];
        homeFinCaseList[0].Verified_by_Finance__c = true;
        homeFinCaseList[0].Sum_of_Total_Commission_for_Aldar__c = 10000;
        homeFinCaseList[0].PaymentReceived__c = true;
        homeFinCaseList[0].CaseCategory__c = 'Aldar Portal';
        homeFinCaseList[0].SubVertical__c =System.Label.Case_Home_finance;
        homeFinCaseList[0].Sub_Status__c=System.Label.Case_Sub_status_loan;
        homeFinCaseList[0].Status = 'Closed';
        csListUpd.add(homeFinCaseList[0]);        
        update csListUpd;        
    }
    
    @isTest
    public static void updateSurveyPoint_Test() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id amcRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('AMC').getRecordTypeId();        
        Case amcCase = TestObjectsFactory.getCaseRecord(amcRT, Constants.PAYMENT_EXTENSION_TYPE, unit[0].Id, 'Walk-In');
        amcCase.Subject='Test Subject';
        amcCase.Status = 'New';      
        amcCase.CaseCategory__c = 'On Demand';
        amcCase.Vertical__c = Constants.DLP_SUB_VERTICAL;
        amcCase.SubVertical__c = 'AMC';
        amcCase.AMC_Closure_Reason__c = System.Label.AMCClosureForComleted;
        insert amcCase;
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> amcCaseList = [Select id,Subject,SubVertical__c,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where Id =:amcCase.id];
        amcCaseList[0].CaseCategory__c = System.Label.ODCaseCategoty;
        amcCaseList[0].SubVertical__c = 'AMC';
        amcCaseList[0].Status = 'Closed';
        amcCaseList[0].Qualtrics_Survey_Required__c = true;
        amcCaseList[0].AMC_Closure_Reason__c = System.Label.AMCClosureForComleted;
        update amcCaseList[0];
    }
    
    @isTest
    public static void beforeInsertCaseFieldMapping_Test() {
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id amcRT =Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('ECSS_Email_to_Case').getRecordTypeId();        
        Case amcCase = TestObjectsFactory.getCaseRecord(amcRT, Constants.PAYMENT_EXTENSION_TYPE, unit[0].Id, 'Walk-In');
        amcCase.Subject='Test Subject';
        amcCase.Status = 'New';      
        amcCase.Priority = 'P3';
        amcCase.Origin = 'Email';        
        amcCase.Description = 'Classification : Internal General Purpose';
        insert amcCase;
    }
        
}