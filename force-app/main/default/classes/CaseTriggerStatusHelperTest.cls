/*
*********************************************************
Apex Class Name    : CaseTriggerStatusHelperTest
Created Date       : 
@description       : Class to test CaseTriggerStatusHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/

// dummy commit
@isTest
public class CaseTriggerStatusHelperTest {
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
        newAccount.OwnerManagerEmail__c = 'test@gmail.com';
        newAccount.OwnerManagerEmail__pc = 'test1@gmail.com';
        AccountTriggerHandler.skipAccountTrigger = true;
        insert newAccount;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc;   
        AccountTriggerHandler.skipAccountTrigger = false;
    }
	@isTest
    public static void caseTriggerStatusHelperTest() {
        Test.StartTest();
        List<Case> casList = new List<Case>();
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id queriesRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();        
        Case reqCase = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit[0].Id, 'Walk-In');
        reqCase.Subject='Test Subject';
        reqCase.AccountId = [Select id from Account][0].id;
        reqCase.Status = 'New';
        reqCase.SubCategory__c = 'Requests for extra GFA';
        casList.add(reqCase);        
        Case reqCase1 = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit[0].Id, Constants.CASE_ORIGIN_CUSTOMER_PORTAL);
        reqCase1.Subject='Test Subject';
        reqCase1.Status = 'New';
        reqCase1.AccountId = [Select id from Account][0].id;
        reqCase1.SubCategory__c = 'Requests for extra GFA';
        reqCase1.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        reqCase1.CaseComments__c = 'Testing After Update Condition';
        casList.add(reqCase1);        
        insert casList;    
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> reqCsList = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where id=:reqCase.Id];
        reqCsList[0].Status = 'Resolved';
        reqCsList[0].FCR__c = false;       
        update reqCsList[0];
        User testuser = [Select id, Name from User Where email = 'test@aldar.com'];
        system.runas(testuser) {       
            TriggerHandler.processedIds = new Set<Id>();
            List<Case> reqCsList1 = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c From Case Where  id=:reqCase1.Id];
            reqCsList1[0].Status = Constants.CLOSED_CASE; 
            reqCsList1[0].StatusReason__c = Constants.WITH_RESOLUTION_CASE;
            update reqCsList1[0];
        }
        Test.stopTest();
    } 
    
}