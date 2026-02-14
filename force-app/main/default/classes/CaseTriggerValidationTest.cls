/*
*********************************************************
Apex Class Name    : CaseTriggerValidationTest
Created Date       : 
@description       : Class to test CaseTriggerValidation
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class CaseTriggerValidationTest {
	@testSetup
    public static void createData(){ 
                Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
            triggerEnabler.Name = 'Asset';
            triggerEnabler.Is_After_Update__c =false;
            triggerEnabler.Is_After_Insert__c =false;
            triggerEnabler.Is_After_Delete__c = false;
            triggerEnabler.Is_Before_Delete__c = false;
            triggerEnabler.Is_Before_Insert__c = false;
            triggerEnabler.Is_Before_Update__c = false;
            insert triggerEnabler;        
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
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc; 
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert salesOrder; 
        CalloutToMuleSoft.updateSOSyncStatus = false;
        List<Case> casList = new List<Case>();
        Id dlpRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case dlpCs = TestObjectsFactory.getCaseRecord(dlpRecId, 'Question', unit.Id, 'Email');
        dlpCs.Subject='Test Subject';
        dlpCs.Status = 'New';
        dlpCs.Single_DLP_slot__c = true;
        insert dlpCs;
        Id queriesRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();        
        Case reqCase = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit.Id, 'Walk-In');
        reqCase.Subject='Test Subject';
        reqCase.AccountId = [Select id from Account][0].id;
        reqCase.Status = 'New';
        reqCase.SubCategory__c = 'Requests for extra GFA';
        reqCase.CaseCategory__c =  Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        reqCase.SRCreated__c = true;
        casList.add(reqCase); 
        Id stRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case standCase = TestObjectsFactory.getCaseRecord(stRecId, 'Question', unit.Id, 'Email');
        standCase.Subject='Test StandardCase Subject';
        standCase.SuppliedEmail = 'test@gmail.com';
        standCase.Status = 'New';
        casList.add(standCase);         
        Id feedbackRecordTypeId = Utilities.getRecordTypeId('Case', Constants.FEEDBACK_CASE_RT);
        Case newFeedbackCase = TestObjectsFactory.getCaseRecord(feedbackRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
        newFeedbackCase.SubVertical__c = 'Defaults & Collection';
        newFeedbackCase.CaseCategory__c = 'Payment Extension';
        newFeedbackCase.RecordId__c = unit.Id;
        newFeedbackCase.OwnerId = [SELECT Id,name from Group where Name = 'Survey Queue'][0].Id;
        casList.add(newFeedbackCase);
        insert casList;
    }
    @isTest
    public static void caseTriggerValidation_InertTest(){
        List<Case> casList = new List<Case>();
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Account newAccount = [Select id from Account limit 1];
        SalesOrder__c salesOrder = [Select id from SalesOrder__c limit 1];
        Id stRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case standCase = TestObjectsFactory.getCaseRecord(stRecId, 'Question', unit.Id, 'Email');
        standCase.Subject='Test Subject';
        standCase.SuppliedEmail = 'test@gmail.com';
        standCase.AccountId = newAccount.id;
        standCase.CaseCategory__c = 'On Demand';
        standCase.SubCategory__c = 'Handyman';
        standCase.SalesOrder__c = salesOrder.id;
        casList.add(standCase);
        Id DLPRT =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case dlpCase = TestObjectsFactory.getCaseRecord(DLPRT, 'Question', unit.Id, 'Email');
        dlpCase.Subject='Test Subject';
        dlpCase.SuppliedEmail = 'test@gmail.com';
        dlpCase.AccountId = newAccount.id;
        dlpCase.CaseCategory__c = 'On Demand';
        dlpCase.SubCategory__c = 'Handyman';
        dlpCase.SubVertical__c = 'DLP';
        dlpCase.Single_DLP_slot__c = true;
        casList.add(dlpCase);
        insert casList; 
        
    }
    @isTest
    public static void caseTriggerValidation_UpdateTest() {   
        List<Case> casList = new List<Case>();
        List<Case> casUpdList = new List<Case>();
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Account newAccount = [Select id from Account limit 1];     
        Id stRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Id dlpRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Id reqRecId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Requests').getRecordTypeId();
        Id feedbackRecordTypeId = Utilities.getRecordTypeId('Case', Constants.FEEDBACK_CASE_RT);
        Case standCase = TestObjectsFactory.getCaseRecord(stRecId, 'Question', unit.Id, 'Email');
        standCase.Subject='Test Subject';
        standCase.Status = 'New';
        standCase.SuppliedEmail = 'test@gmail.com';
        casList.add(standCase);
        Case dlpCase = TestObjectsFactory.getCaseRecord(dlpRecId, 'Question', unit.Id, 'Email');
        dlpCase.Subject='Test Subject';
        dlpCase.Status = 'New';
        dlpCase.Single_DLP_slot__c = true;
        dlpCase.OwnerId = [SELECT Id,name from Group where Name = 'Post DLP Queue'][0].Id;
        casList.add(dlpCase);
        insert casList;
        TriggerHandler.processedIds = new Set<Id>();
        standCase.Status = 'Closed';
        update standCase;
        TriggerHandler.processedIds = new Set<Id>();
        Case reqCase = [Select id, status,SRCreated__c,CaseCategory__c,SubCategory__c from case where RecordTypeId =:reqRecId limit 1];
        reqCase.Status = 'Closed';
        casUpdList.add(reqCase);
        Case dlpCase1 = [Select id, OwnerId,Single_DLP_slot__c from case where Id =:dlpCase.Id limit 1];
        dlpCase1.OwnerId = [SELECT Id,name from Group where Name = 'Survey Queue'][0].Id;
        casUpdList.add(dlpCase1);
        Case feedbackCase = [Select id, OwnerId,Single_DLP_slot__c from case where RecordTypeId =:feedbackRecordTypeId limit 1];
        feedbackCase.OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1][0].Id;
        casUpdList.add(feedbackCase);
        update casUpdList;
    }
    @isTest
    public static void caseTriggerValidationTest(){
        Test.StartTest();
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Account newAccount = [Select id from Account limit 1];
        Opportunity opp = [Select id from Opportunity limit 1];
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert salesOrder; 
        CalloutToMuleSoft.updateSOSyncStatus = false;
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Handyman', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages'),
            new Product2(Name = 'Duct Cleaning', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages'),
            new Product2(Name = 'Pest Control', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages')
        };
        insert products; 
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location'; 
		loc.IsInventoryLocation = true;
        insert loc;
                        
        List<ProductItem> lstPI = new List<ProductItem>();
        for(Product2 p:products){
        	lstPI.add (new ProductItem(Product2Id = p.Id, QuantityOnHand=5,locationId=loc.Id));    
        }
        insert lstPI;
       
        List<OpportunityOfferLine__c> lstOppLi =  new List<OpportunityOfferLine__c>{
            new OpportunityOfferLine__c(Name='Handyman',SalesOrder__c=salesOrder.Id ,Product_Item__c=lstPI[0].Id),
			new OpportunityOfferLine__c(Name='Duct Cleaning',SalesOrder__c=salesOrder.Id, Product_Item__c=lstPI[1].Id),
            new OpportunityOfferLine__c(Name='Pest Control',SalesOrder__c=salesOrder.Id, Product_Item__c=lstPI[2].Id)
        };
        insert lstOppLi;
        
        Id recTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case newCase = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit.Id, 'Email');
        newCase.Subject='Test Subject';
        newCase.SuppliedEmail = 'test@gmail.com';
        newCase.SalesOrder__c = salesOrder.id;
        newCase.AccountId = newAccount.id;
        newCase.CaseCategory__c = 'On Demand';
        newCase.SubCategory__c = 'Handyman';
        newCase.ProductId = products[0].Id;        
        insert newCase;  
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> newCsList = [Select id,Subject,SalesOrder__c,SRCreated__c,Status,SubCategory__c,CaseCategory__c,ProductId,Customer_Follow_up_Count__c,FCR__c,OwnerId From Case Where Id =:newCase.id];
        newCsList[0].SRCreated__c = true;
        newCsList[0].Status = 'Closed';
        update newCsList[0];
        Map<Id, Case> casMap = new Map<Id, Case>();
        Set<Id> csIds = new Set<id>();
        Map<Id,Set<Id>> mapSOProdId = new Map<Id,Set<Id>>();
        for(Case cs : newCsList) {
            casMap.put(cs.id,cs);
            csIds.add(cs.id);
            mapSOProdId.put(cs.SalesOrder__c,new Set<Id>()); 
            mapSOProdId.get(cs.SalesOrder__c).add(cs.ProductId); 
        }        
        CaseTriggerValidation.handleTransferredCases(casMap);
        CaseTriggerValidation.validateDLPCases(newCsList);
        CaseTriggerValidation.validateCasewithOpenChildCase(newCsList,csIds); 
        Test.StopTest();
    }
     @isTest
    public static void duplicateCaseByAssetAndCaseCategoryTest(){
        Unit__c unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold' limit 1];
        Id accId = [Select id from Account][0].id;
        Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert oAcc;
        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;
        Contact aCon = new Contact();
        aCon.LastName = 'Alice';
        aCon.FirstName = 'Alice';
        aCon.Email ='test@gmail.com';
        aCon.AccountId = oAcc.Id;
        aCon.BrokerType__c = Constants.AGENCY_ADMIN;
        insert aCon;
        Id queriesRT =Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('ECSS_Complaints').getRecordTypeId();     
        //Case reqCase=TestObjectsFactory.getProvisCaseNoAccount();
        Case reqCase = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit.Id, 'Walk-In');
        reqCase.recordtypeId = queriesRT;
        reqCase.Subject='Test Subject';
        reqCase.AccountId = accId;
        reqCase.Status = 'New';
        reqCase.AssetId = testAsset.Id;
        reqCase.SubCategory__c = 'Requests for extra GFA';
        reqCase.CaseCategory__c = 'Out of home';
        reqCase.SRCreated__c = true;
        reqCase.ContactId = aCon.Id;
        Insert reqCase;
    }
}