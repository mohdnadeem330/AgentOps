/*
*********************************************************
Apex Class Name    : CorporateLegalCaseTriggerHelperTest
Created Date       : 
@description       : Class to test CorporateLegalCaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class CorporateLegalCaseTriggerHelperTest {
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
        insert newAccount;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
    }

    @isTest
    public static void beforeInsertCorporateLegal_Test() {
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Account newAccount = [Select id from Account limit 1];
        Id dlpRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Corporate_Legal').getRecordTypeId();
        Case dlpCs = TestObjectsFactory.getCaseRecord(dlpRecId, 'Question', unit.Id, 'Email');
        dlpCs.Subject='Test Subject';
        dlpCs.Status = 'New';
        dlpCs.Single_DLP_slot__c = true;
        test.starttest();
        	insert dlpCs;
        test.stoptest();
    }
}