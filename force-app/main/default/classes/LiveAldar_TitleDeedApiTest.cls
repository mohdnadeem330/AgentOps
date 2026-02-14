@isTest
public class LiveAldar_TitleDeedApiTest {
	@testSetUp
    public static void testdata1(){
       
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
		Id TitleDeedRegistartionId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_RT);

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
		//opp.Resaleservicefeeapprovalstatus__c='Approved';
        insert opp;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
		unit.Name = 'MAYAN-B1-1004';  
        insert unit;
        
        //Id TitleDeedRegistartionId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_DEV_RT);
        list<SalesOrder__c> salesOrders = new list<SalesOrder__c>();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.NetAmount__c =300;
        salesOrders.add(salesOrder);
        insert salesOrders;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
		
        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;

        //TITLE DEED RECORD SETUP STARTS
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.TITLE_DEED_REGISTRATION_DEV_RT, 'TitleDeedRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.TITLE_DEED_REGISTRATION_DEV_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;     
		//TITLE DEED RECORD SETUP ENDS

		/*HANDOVER RECORD SETUP STARTS
		HexaBPM__Step_Template__c handoverStepTemplate = TestObjectsFactory.getStepTemplate(Constants.HANDOVER_RT, 'Handover');
        insert handoverStepTemplate;
        
        HexaBPM__SR_Template__c handoverSRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.HANDOVER_RT);        
        insert handoverSRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c handoverobjSRSteps = TestObjectsFactory.getSRStep(handoverSRTemplateDetailRecord.Id, handoverStepTemplate.Id);
        insert handoverobjSRSteps;	
		//HANDOVER RECORD SETUP ENDS*/

        HexaBPM__Service_Request__c parentTitleDeedSR = TestObjectsFactory.getServiceRequest(Submitted.Id, unit.Id,'Title Deed Registration', TitleDeedRegistartionId, SRTemplateDetailRecord.Id);
        insert parentTitleDeedSR;

        HexaBPM__Service_Request__c childTitleDeedSR = TestObjectsFactory.getServiceRequest(Submitted.Id, unit.Id,'Title Deed Registration',TitleDeedRegistartionId, SRTemplateDetailRecord.Id);
        childTitleDeedSR.SalesOrder__c = salesOrder.Id;
        childTitleDeedSR.Unit__c = unit.Id;  
		//newSR.UnitName__c='name';
        childTitleDeedSR.WaivedPercentage__c = 2;
        childTitleDeedSR.ReallocationAmount__c = 100;
        childTitleDeedSR.No_Charge_Fee_Required__c = false;
		childTitleDeedSR.HexaBPM__Customer__c=acc.Id;
        childTitleDeedSR.HexaBPM__External_SR_Status__c=Closed.Id;
		childTitleDeedSR.HexaBPM__Parent_SR__c=parentTitleDeedSR.Id;
		childTitleDeedSR.HexaBPM__Closed_Date_Time__c=DateTime.now().addDays(5);
        insert childTitleDeedSR;
        
		/*HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Title_Deed_Copy';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
	
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;

		HexaBPM__SR_Doc__c titledeedDoc = new HexaBPM__SR_Doc__c();
        titledeedDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        titledeedDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        titledeedDoc.HexaBPM__Service_Request__c = childTitleDeedSR.id;
		titledeedDoc.HexaBPM__Status__c ='Uploaded';
        insert titledeedDoc;*/
        
	
        HexaBPM__Step__c newStep = new HexaBPM__Step__c();
        newStep.HexaBPM__SR__c = childTitleDeedSR.id;
        newStep.HexaBPM__Due_Date__c = System.Now().addDays(2);
        newStep.HexaBPM__Step_No__c = 10;
        newStep.HexaBPM__SR_Step__c = objSRSteps.Id;
        newStep.HexaBPM__Step_Template__c = objStepTemplate.id;
        newStep.HexaBPM__Step_Notes__c = 'test';
        newStep.HexaBPM__Summary__c ='CM Validation';
        insert newStep;
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.ServiceRequest__c = childTitleDeedSR.Id;
        salesOrderOtherCharges.Account__c = acc.Id;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.SalesOrder__c = salesOrder.Id;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        insert salesOrderOtherCharges;
        
    }
	@isTest
    public static void titledeedtest(){
	HexaBPM__Service_Request__c unitName = [Select id,Unit__r.Name from HexaBPM__Service_Request__c WHERE Id IN(SELECT HexaBPM__SR__c FROM HexaBPM__Step__c) ORDER BY CreatedDate limit 1];
	system.debug('unitName.Unit__r.Name'+unitName.Unit__r.Name);
    account Acc = [Select id from Account limit 1];
	Test.startTest();
		RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/query/titledeed';
        req.params.put('UnitName',unitName.Unit__r.Name);
        req.params.put('AccountId',Acc.Id);
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
		LiveAldar_TitleDeedApi.doPost(Acc.Id,unitName.Unit__r.Name);
	Test.stopTest();
    }
    @isTest
    public static void titledeedtest1(){
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        HexaBPM__Step_Template__c handoverStepTemplate = TestObjectsFactory.getStepTemplate(Constants.HANDOVER_RT, 'Handover');
        insert handoverStepTemplate;
        
        HexaBPM__SR_Template__c handoverSRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.HANDOVER_RT);        
        insert handoverSRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c handoverobjSRSteps = TestObjectsFactory.getSRStep(handoverSRTemplateDetailRecord.Id, handoverStepTemplate.Id);
        insert handoverobjSRSteps;	
        
        HexaBPM__Service_Request__c unitName = [Select id,Unit__r.Name from HexaBPM__Service_Request__c WHERE Id IN(SELECT HexaBPM__SR__c FROM HexaBPM__Step__c) ORDER BY CreatedDate limit 1];
        system.debug('unitName.Unit__r.Name'+unitName.Unit__r.Name);
        account Acc = [Select id from Account limit 1];

        SalesOrder__c salesOrder = [Select id from SalesOrder__c limit 1];
        
        HexaBPM__SR_Status__c srStatus=[Select id,Name from HexaBPM__SR_Status__c WHERE Name='Closed' limit 1];
		
		HexaBPM__Service_Request__c handOverSR = TestObjectsFactory.getServiceRequest(srStatus.id, unitname.unit__c, Constants.HANDOVER_RT, handoverRecordTypeId, handoverSRTemplateDetailRecord.Id);
        handOverSR.ChargeCollected__c = 2000;
		handOverSR.HexaBPM__Customer__c=acc.Id;
		Test.startTest();
        insert handOverSR;
		
         List<HexaBPM__Service_Request__c> results = [SELECT Id, HexaBPM__External_Status_Name__c, HexaBPM__Parent_SR__c, HexaBPM__Closed_Date_Time__c, HandoverDetail__r.HandoverCompletionDate__c  FROM HexaBPM__Service_Request__c WHERE (Unit__c =: handOverSR.unit__c AND HexaBPM__Customer__c =: handOverSR.HexaBPM__Customer__c  AND HexaBPM__External_Status_Name__c != 'Draft'  AND HexaBPM__External_Status_Name__c != 'Cancelled' AND SRType__c = 'Handover')  ORDER BY CreatedDate DESC LIMIT 1];                                                  

		RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/query/titledeed';
        req.params.put('UnitName',unitName.Unit__c);
        req.params.put('AccountId',Acc.Id);
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
		LiveAldar_TitleDeedApi.doPost(Acc.Id,unitName.Unit__r.Name);
	Test.stopTest();
		
    }

    @isTest
    public static void catchException(){
        HexaBPM__Service_Request__c unitNames = [Select id,Unit__r.Name from HexaBPM__Service_Request__c WHERE Id IN(SELECT HexaBPM__SR__c FROM HexaBPM__Step__c) ORDER BY CreatedDate limit 1];
	
    account Acct = [Select id from Account limit 1];
	Test.startTest();
		RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/query/titledeed';
        req.params.put('UnitName','');
        req.params.put('AccountId',Acct.Id);
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
		LiveAldar_TitleDeedApi.doPost(Acct.Id,'');
	Test.stopTest();
    }

	@isTest
    public static void handoverServiceRequestOnly(){
	account Acc = [Select id from Account limit 1]; 
	
		Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        HexaBPM__Step_Template__c handoverStepTemplate = TestObjectsFactory.getStepTemplate(Constants.HANDOVER_RT, 'Handover');
        insert handoverStepTemplate;
        
        HexaBPM__SR_Template__c handoverSRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.HANDOVER_RT);        
        insert handoverSRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c handoverobjSRSteps = TestObjectsFactory.getSRStep(handoverSRTemplateDetailRecord.Id, handoverStepTemplate.Id);
        insert handoverobjSRSteps;	
        
        //HexaBPM__Service_Request__c unitName = [Select id,Unit__r.Name from HexaBPM__Service_Request__c WHERE Id IN(SELECT HexaBPM__SR__c FROM HexaBPM__Step__c) ORDER BY CreatedDate limit 1];
        //system.debug('unitName.Unit__r.Name'+unitName.Unit__r.Name);
        account Acctt = [Select id from Account limit 1];
		unit__c unit =[SELECT Id,Name FROM unit__c LIMIT 1 ];

        SalesOrder__c salesOrder = [Select id from SalesOrder__c limit 1];
        
        HexaBPM__SR_Status__c srStatus=[Select id,Name from HexaBPM__SR_Status__c WHERE Name='Closed' limit 1];
		
		HexaBPM__Service_Request__c handoverSROnly = TestObjectsFactory.getServiceRequest(srStatus.id, unit.Id, Constants.HANDOVER_RT, handoverRecordTypeId, handoverSRTemplateDetailRecord.Id);
        handoverSROnly.ChargeCollected__c = 7777;
		handoverSROnly.HexaBPM__Customer__c=Acctt.Id;
		Test.startTest();
        insert handoverSROnly;
		HexaBPM__Service_Request__c handoverServiceRequestOnly = [Select id,Unit__r.Name from HexaBPM__Service_Request__c WHERE ChargeCollected__c=:7777 ORDER BY CreatedDate limit 1];
		RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/query/titledeed';
        req.params.put('UnitName',unit.Id);
        req.params.put('AccountId',Acctt.Id);
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
		LiveAldar_TitleDeedApi.doPost(Acctt.Id,unit.Name);
		//LiveAldar_TitleDeedApi.doPost('Acctt.Id',handoverServiceRequestOnly.Unit__r.Name);
	Test.stopTest();
	}
    
}