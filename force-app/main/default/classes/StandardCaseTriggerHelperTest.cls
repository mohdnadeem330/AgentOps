/*
*********************************************************
Apex Class Name    : StandardCaseTriggerHelperTest
Created Date       : 
@description       : Class to test StandardCaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class StandardCaseTriggerHelperTest {
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
    public static void beforeInsertStandard_Test() {
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Account newAccount = [Select id from Account limit 1];
        Id stRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case standCase = TestObjectsFactory.getCaseRecord(stRecId, 'Question', unit.Id, 'Email');
        standCase.Subject='Test StandardCase Subject';
        standCase.SuppliedEmail = 'test@gmail.com';
        standCase.Status = 'New';
        test.starttest();
        	insert standCase;
        test.stoptest();
    }
}