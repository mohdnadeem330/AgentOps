@isTest
public class CustomerSingleCaseSRDetailsAPITest {
	
    
     @testSetUp
    public static void testData(){
        LIst<HexaBPM__SR_Doc__c> srdocList = new List<HexaBPM__SR_Doc__c>();
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert acc;
        
        Account jbAcc = new Account();
        jbAcc.FirstName='Test';
        jbAcc.LastName= 'Account JB';
        jbAcc.PersonEmail='testjbAcc@gmail.com';
        jbAcc.RecordTypeId = personAccountRecordTypeId;
        jbAcc.CustomerAppWebUser__c=false;
        insert jbAcc;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        HexaBPM__SR_Status__c SRStatus = new HexaBPM__SR_Status__c();
        SRStatus=TestObjectsFactory.getSRStatus('Submitted');
        insert SRStatus;
        system.debug('SRStatus info::'+SRStatus);
        
        HexaBPM__SR_Status__c cancelledStatus = new HexaBPM__SR_Status__c();
        cancelledStatus=TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelledStatus;
        
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        
        HexaBPM__Service_Request__c SR=TestObjectsFactory.getServiceRequest(SRStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        SR.TransferSellingPrice__c=19500.01;
        SR.HexaBPM__Customer__c=acc.Id;
        SR.Origin__c='Customer Portal';
        SR.HexaBPM__External_SR_Status__c =  SRStatus.Id;
        SR.HexaBPM__Internal_SR_Status__c =  SRStatus.Id;
        SR.BuyerName__c = acc.Id;
        SR.BuyerEmail__c = acc.personEmail;
        //SR.HexaBPM__External_Status_Name__c=SRStatus.Id;
        insert SR;
        System.debug('SR ID ::'+ SR+'HexaBPM__External_Status_Name__c::'+SR.HexaBPM__External_Status_Name__c+'Origin::'+ SR.Origin__c);
        system.debug('SR status::'+ SR.HexaBPM__External_SR_Status__c);
        system.debug('SR status r name::'+  SR.HexaBPM__External_Status_Name__c);
        
        
        HexaBPM__Service_Request__c invalidSR=TestObjectsFactory.getServiceRequest(cancelledStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        invalidSR.TransferSellingPrice__c= 19501.01;
        insert invalidSR;
        
        
        Case testCase = new Case(
                AccountId = acc.Id,
                recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
                Type = 'NOC',
                Development_Name__c = 'Yas Island',
                Status = 'New',
                Subject = 'Test NOC Application',
                IPS_Received_from_ADM__c = 'Yes'
            );
            insert testCase;
        
        
    }
    
     @isTest
    static void SRScenario(){
        
         list<HexaBPM__Service_Request__c> validServiceRequest =[SELECT Id FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c= 19500.01];
         String sRId = validServiceRequest[0].Id ;
         String inputPayload = '{' + 
   
            '"entityId": "' + sRId + '"' +
             
            '}';
        System.debug('inputPayload: ' + inputPayload);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/getCaseOrSRDetail';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CustomerSingleCaseSRDetailsAPI.getCaseSRDetails();
        Test.stopTest();
    }
    
     @isTest
    static void SRScenarioSecond(){
        
         list<Case> caseList = [SELECT Id FROM Case WHERE Subject = 'Test NOC Application' LIMIT 1];
         String sRId = caseList[0].Id ;
         String inputPayload = '{' + 
   
            '"entityId": "' + sRId + '"' +
             
            '}';
        System.debug('inputPayload: ' + inputPayload);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/getCaseOrSRDetail';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CustomerSingleCaseSRDetailsAPI.getCaseSRDetails();
        Test.stopTest();
    }
    
 
    
    @isTest
    static void catchExceptionMethod(){
        
        
        Test.startTest();
       
        String inputPayload = 'incorrectJSon';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/getCaseOrSRDetail';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
         CustomerSingleCaseSRDetailsAPI.getCaseSRDetails();
        Test.stopTest();
        
        
    }
}