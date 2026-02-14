/*
*********************************************************
Apex Class Name    : CaseTriggerHandlerNewTest
Created Date       : 
@description       : Class to test CaseTriggerHandlerNew and CaseTriggerHelper
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
@isTest
public class CaseTriggerHandlerNewTest {
    
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
        insert newAccount;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert salesOrder; 
        CalloutToMuleSoft.updateSOSyncStatus = false;
        HexaBPM__Service_Request__c titleDeed = new HexaBPM__Service_Request__c();
        titleDeed.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.HANDOVER_RT);
        titleDeed.SRType__c = Constants.HANDOVER_RT;
        titleDeed.Unit__c = unit.Id;
        insert titleDeed;
        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        objLead1.agencyName__c = 'Address Point Properties L.L.C';
        objLead1.agentName__c = 'Brooke Reynolds';
        objLead1.offer1__c = '2020 Free for 3 offer';
        insert objLead1;
        Id reqRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Requests').getRecordTypeId();        
        Case reqCase = TestObjectsFactory.getCaseRecord(reqRT, 'Question', unit.Id, 'Walk-In');
        reqCase.Subject='Test Request Subject';
        reqCase.Status = 'New';
        reqCase.Assigned_To__c = null;
        reqCase.SubCategory__c = 'Requests for extra GFA';
        reqCase.Priority = 'P3';     
        reqCase.CaseCategory__c = System.label.Case_KAR_category;
        insert reqCase;                
    }
    
    @isTest
    public static void updateOffLineQtyInprogressTest(){
        Test.StartTest();
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.OwnerManagerEmail__c = 'test@gmail.com';
        newAccount.OwnerManagerEmail__pc = 'test1@gmail.com';
        insert newAccount;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
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
		CaseTriggerHelper.updateOffLineQtyInprogress(mapSOProdId,'Create');   
        CaseTriggerHelper.updateOffLineQtyInprogress(mapSOProdId,'Closed');
        CaseTriggerHelper.updateOffLineQtyInprogress(mapSOProdId,'Cancelled'); 
        Test.StopTest();
    }
    @isTest
    public static void caseTriggerHelperTest1() {
        Test.StartTest();
        List<Case> caseList =new List<Case>(); 
        Account newAccount = [Select id, Name,PersonContactId from Account limit 1];
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id dlpRecTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case dlpCase = TestObjectsFactory.getCaseRecord(dlpRecTpId, 'Question', unit[0].Id, 'Email');
        dlpCase.ContactId = newAccount.PersonContactId;
        dlpCase.Subject='Test Subject';
        dlpCase.SubVertical__c = Constants.DLP_SUB_VERTICAL;
        dlpCase.CaseCategory__c = 'Civil';
        dlpCase.ResolutionType__c = 'Repair';
        dlpCase.SubCategory__c = 'Aluminium';
        dlpCase.ProblemCode__c ='CM-PQA- Window frame';
        dlpCase.IncidentDescription__c = 'Scratched';
        dlpCase.Single_DLP_slot__c = true;
        dlpCase.Status = 'New';
        dlpCase.Vertical__c = Constants.DLP_VERTICAL;
        caseList.add(dlpCase);
        Id dlpRecTpId1 =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case newCase1 = TestObjectsFactory.getCaseRecord(dlpRecTpId1, 'Question', unit[0].Id, 'Email');
        newCase1.ContactId = newAccount.PersonContactId;
        newCase1.Subject='Test Subject';
        newCase1.SubVertical__c = 'DLP';
        newCase1.Single_DLP_slot__c = true;
        newCase1.AccountId = newAccount.id;
        newCase1.Status = 'New';
        caseList.add(newCase1);
        insert caseList;
       	TriggerHandler.processedIds = new Set<Id>();
        newCase1.Status = Constants.CASE_WORK_IN_PROGRESS;
        newCase1.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        update newCase1;
        Test.StopTest();
    } 
    @isTest
    public static void caseTriggerHelperTest2() {
         User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Id amcRT = Schema.SObjectType.case.getRecordTypeInfosByName().get('AMC').getRecordTypeId(); 
		List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        // 2. Insert contact
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
      	insert orgAcc;
      	Contact conta1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Case amcCase = TestObjectsFactory.getCaseRecord(amcRT, Constants.PAYMENT_EXTENSION_TYPE, unit[0].Id, 'Walk-In');
        amcCase.Status = 'New';
        amcCase.CaseCategory__c = 'On Demand';
        amcCase.SubVertical__c = System.Label.Case_Subvertical_Onboarding;
        amcCase.OwnerId = u.Id;
        amcCase.Origin = 'Phone';                     
        amcCase.Vertical__c = 'Sales';                 
        amcCase.Survey_Required__c = false;            
        amcCase.Qualtrics_Survey_Required__c = true;   
        amcCase.DLP_Closure_Reason__c = 'Attended';
        amcCase.AMC_Closure_Reason__c = 'Customer Not interested';
        amcCase.Subject = 'Survey Required Case';
        amcCase.ContactId = conta1.Id;
        insert amcCase; 

        Test.startTest();
        TriggerHandler.processedIds = new Set<Id>();
        amcCase.Status = Constants.CASE_WORK_IN_PROGRESS;
        amcCase.CaseCategory__c = 'GCEO Comms';
        update amcCase;
        TriggerHandler.processedIds = new Set<Id>();
        amcCase.Status = 'Closed';
        update amcCase;
        Test.stopTest();	        
    }
    @isTest
    public static void caseTriggerHelperTest3() {                	
        TriggerHandler.processedIds = new Set<Id>();
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        List<Case> queCaseList = [Select id,Subject,Assigned_To__c,Resolved_Time__c,Status,SubCategory__c,CaseCategory__c,Customer_Follow_up_Count__c,FCR__c,RecordTypeId,Recordtype_Name__c,OwnerId,AccountId From Case Where Subject ='Test Request Subject'];
        queCaseList[0].CaseCategory__c = 'Facility Management';
        queCaseList[0].SubCategory__c = 'Air Conditioning';
        Test.StartTest();
        update queCaseList[0];
        Map<Id,Case> caseMap = new Map<Id,Case>();
        for(Case cs: queCaseList) {
          	 caseMap.put(cs.Id,cs); 
        }
        List<Case_Field_Dependency_Revised__mdt> mockDependencies = new List<Case_Field_Dependency_Revised__mdt>{
            new Case_Field_Dependency_Revised__mdt(
                Category__c = 'Facility Management',
                Sub_Category__c = 'SubCategory1',
                ECSS_Is_ECSS__c = true,
                ECSS_Is_Eltizam__c = true,
                Sub_Vertical__c = 'SubVertical1',
                Auto_Assingment__c = Constants.BROKER_QUEUE
            ),
            new Case_Field_Dependency_Revised__mdt(
                Category__c = 'Facility Management',
                Sub_Category__c = 'SubCategory2',
                ECSS_Is_ECSS__c = true,
                ECSS_Is_Eltizam__c = false,
                Sub_Vertical__c = 'SubVertical2',
                Auto_Assingment__c = Constants.SALES_QUEUE
            )
        };
        Map<Id,Case_Field_Dependency_Revised__mdt> mtdMap = new Map<Id,Case_Field_Dependency_Revised__mdt>([SELECT Id,Auto_Assingment__c,Category__c FROM Case_Field_Dependency_Revised__mdt Where Category__c = 'Facility Management']);
        CaseTriggerHelper.autoassigmentBulk(caseMap,mtdMap);
        CaseTriggerHelper.checkUserQueue('Sales queue');
        CaseTriggerHelper.createCaseDocuments(queCaseList);
        CaseTriggerHelper.createResolvertask(queCaseList);
        CaseTriggerHelper.getSystemMessagesMap();
        Test.StopTest();
    }
    
    /*@isTest
    public static void caseTriggerHelperTest4() { 
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id recTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        Case newCase = TestObjectsFactory.getCaseRecord(recTpId, 'Question', unit[0].Id, 'Email');
        newCase.Subject='Test Subject';
        newCase.SuppliedEmail = 'test@gmail.com';
        newCase.CaseCategory__c = 'On Demand';
        newCase.SubCategory__c = 'Handyman';
        newCase.SubVertical__c = Constants.DLP_SUB_VERTICAL;
        insert newCase;  
        TriggerHandler.processedIds = new Set<Id>();
        List<Case> newCsList = [Select id,Subject,SalesOrder__c,SRCreated__c,Status,SubCategory__c,CaseCategory__c,ProductId,Customer_Follow_up_Count__c,FCR__c,OwnerId From Case Where Id =:newCase.id];
        newCsList[0].SRCreated__c = true;
        newCsList[0].CaseCategory__c = 'MEP';
        update newCsList[0];
        
    }*/
    
	
}