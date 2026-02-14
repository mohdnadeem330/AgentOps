/*
*********************************************************
Apex Class Name    : NonCustomerSupportAndECSSCaseHelperTest
Created Date       : 
@description       : Class to test NonCustomerSupportAndECSSCaseHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class NonCustomerSupportAndECSSCaseHelperTest {
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
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert salesOrder; 
        CalloutToMuleSoft.updateSOSyncStatus = false;
        HexaBPM__Service_Request__c titleDeed = new HexaBPM__Service_Request__c();
        titleDeed.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_RT);
        titleDeed.SRType__c = Constants.TITLE_DEED_REGISTRATION_RT;
        titleDeed.Unit__c = unit.Id;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        insert titleDeed;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        objLead1.agencyName__c = 'Address Point Properties L.L.C';
        objLead1.agentName__c = 'Brooke Reynolds';
        objLead1.offer1__c = '2020 Free for 3 offer';
        insert objLead1;   
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc;   
        AccountTriggerHandler.skipAccountTrigger = false;
    }
     @isTest
    public static void NonCustomerSupportAndECSSCase_InsertTest() {
        List<Case> casList = new List<Case>();
        Account newAccount = [Select id from Account limit 1];
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id recTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();        
        Case standCase = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Walk-In');
        standCase.Subject='Test Subject';
        standCase.AccountId = newAccount.id;
        standCase.Status = 'New';
        standCase.RecordId__c = [Select id from HexaBPM__Service_Request__c][0].Id;
        standCase.CaseCategory__c = Constants.QUALTRICS_SURVEY_CATEGORY;
        standCase.SubCategory__c = Constants.NO_RESPONSE_SUB_CATEGORY;
        standCase.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
        casList.add(standCase);
        Case standCase1 = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Walk-In');
        standCase1.Subject='Test Subject';
        standCase1.AccountId = newAccount.id;
        standCase1.Status = 'New';
        standCase1.RecordId__c = [Select id from SalesOrder__c][0].Id;
        standCase1.SubVertical__c = 'Customer Care';
        standCase1.SubCategory__c = 'PPM Visit';
        casList.add(standCase1);
        Case standCase2 = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Walk-In');
        standCase2.Subject='Test Subject';
        standCase2.AccountId = newAccount.id;
        standCase2.Status = 'New';
        standCase2.SubVertical__c = System.Label.Case_Subvertical_Onboarding;
        standCase2.SubCategory__c = 'Emergency';
        standCase2.RecordId__c = [Select id from Lead][0].Id;        
        casList.add(standCase2);
        Case standCase3 = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Walk-In');
        standCase3.Subject='Test Subject';
        standCase3.AccountId = newAccount.id;
        standCase3.Status = 'New';
        standCase3.SubVertical__c = 'CMO';
        standCase3.SubCategory__c = 'Emergency';
        standCase3.RecordId__c = [Select id from Opportunity][0].Id;        
        casList.add(standCase3);
        Test.StartTest();
        insert casList; 
        Test.stopTest();
    }
    @isTest
    public static void NonCustomerSupportAndECSSCase_UpdateTest() {
        Test.startTest();
        List<case> insCaseList = new List<Case>();
        Account ac = [SELECT PersonContactId  FROM Account LIMIT 1]; 
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id recTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();        
        Case standCase = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Walk-In');
        standCase.Subject='Test Subject';
        standCase.AccountId = ac.id;
        standCase.Status = 'New';
        standCase.RecordId__c = [Select id from HexaBPM__Service_Request__c][0].Id;
        standCase.CaseCategory__c = Constants.QUALTRICS_SURVEY_CATEGORY;
        standCase.SubCategory__c = Constants.NO_RESPONSE_SUB_CATEGORY;
        standCase.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
        insCaseList.add(standCase);
        Id recordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByName().get('DLP').getRecordTypeId();
        Case c = new Case(ContactId = ac.PersonContactId,CustomerType__c='Owner',RecordTypeId=recordTypeId,Unit__c=unit[0].Id,Vertical__c='DLP',Origin=Constants.SURVEY_CASE_ORIGIN,SubVertical__c='DLP',CaseCategory__c=Constants.QUALTRICS_SURVEY_CATEGORY,SubCategory__c='Aluminium',ResolutionType__c='Replace',Skills_Required__c='Electrician',Single_DLP_slot__c=true);
        insCaseList.add(c);
        insert insCaseList;
        List<Case> casUpd = new List<Case>();
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> reqCsList1 = [Select id,Subject,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c,ContactId,OwnerId From Case Where Id =:standCase.id];
        reqCsList1[0].Vertical__c = 'ADM'; 
        reqCsList1[0].SubVertical__c = 'CMO';
        reqCsList1[0].SubCategory__c = 'Requests for extra GFA';
        casUpd.add(reqCsList1[0]);               
        TriggerHandler.processedIds = new Set<Id>();
        c.Origin = 'Email';
        c.Ownership_Bulk_Changed__c = true;
        c.Vertical__c = Constants.DLP_VERTICAL;
        c.SubVertical__c = Constants.DLP_SUB_VERTICAL;
        c.OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1][0].Id;
		casUpd.add(c);    
        update casUpd;
        NonCustomerSupportAndECSSCaseHelper.taskCreationForCase(reqCsList1);
        Test.stopTest(); 
    }
}