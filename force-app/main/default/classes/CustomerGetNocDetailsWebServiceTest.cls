@isTest
public class CustomerGetNocDetailsWebServiceTest {
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
        
        HexaBPM__Document_Master__c ownerAssoDocMaster = new HexaBPM__Document_Master__c();
        ownerAssoDocMaster.HexaBPM__Code__c = 'Assignment_of_Service_Charge';
        ownerAssoDocMaster.HexaBPM__Available_to_client__c = true;
        ownerAssoDocMaster.AvailableForCustomer__c=true;
        insert ownerAssoDocMaster;
        
        HexaBPM__SR_Template_Docs__c ownerAssoSRTemplate = new HexaBPM__SR_Template_Docs__c();
        ownerAssoSRTemplate.HexaBPM__Document_Master__c = ownerAssoDocMaster.id ;
        insert ownerAssoSRTemplate;
        
        HexaBPM__SR_Doc__c ownerAssoSRDoc = new HexaBPM__SR_Doc__c();
        ownerAssoSRDoc.HexaBPM__Document_Master__c = ownerAssoDocMaster.id  ;
        ownerAssoSRDoc.HexaBPM__SR_Template_Doc__c = ownerAssoSRTemplate.id;
        ownerAssoSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        ownerAssoSRDoc.Name='Owner Association Letter' ;
        srdocList.add(ownerAssoSRDoc);
        
        HexaBPM__Document_Master__c doaDocMaster = new HexaBPM__Document_Master__c();
        doaDocMaster.HexaBPM__Code__c = 'Document_of_Adherence';
        doaDocMaster.HexaBPM__Available_to_client__c = true;
        doaDocMaster.AvailableForCustomer__c=true;
        insert doaDocMaster;
        
        HexaBPM__SR_Template_Docs__c doaSRTemplate = new HexaBPM__SR_Template_Docs__c();
        doaSRTemplate.HexaBPM__Document_Master__c = ownerAssoDocMaster.id ;
        insert doaSRTemplate;
        
        HexaBPM__SR_Doc__c doaSRDoc = new HexaBPM__SR_Doc__c();
        doaSRDoc.HexaBPM__Document_Master__c = ownerAssoDocMaster.id  ;
        doaSRDoc.HexaBPM__SR_Template_Doc__c = doaSRTemplate.id;
        doaSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        doaSRDoc.Name='Document of Adherence' ;
        insert doaSRDoc;
        
        HexaBPM__Document_Master__c signedNOCCopyDocMaster = new HexaBPM__Document_Master__c();
        signedNOCCopyDocMaster.HexaBPM__Code__c = 'Signed_NOC_Copy';
        signedNOCCopyDocMaster.HexaBPM__Available_to_client__c = true;
        signedNOCCopyDocMaster.AvailableForCustomer__c=true;
        insert signedNOCCopyDocMaster;
        
        HexaBPM__SR_Template_Docs__c signedNOCCopySRTemplate = new HexaBPM__SR_Template_Docs__c();
        signedNOCCopySRTemplate.HexaBPM__Document_Master__c = signedNOCCopyDocMaster.id ;
        insert signedNOCCopySRTemplate;
        
        HexaBPM__SR_Doc__c signedNOCCopySRDoc = new HexaBPM__SR_Doc__c();
        signedNOCCopySRDoc.HexaBPM__Document_Master__c = signedNOCCopyDocMaster.id  ;
        signedNOCCopySRDoc.HexaBPM__SR_Template_Doc__c = signedNOCCopySRTemplate.id;
        signedNOCCopySRDoc.HexaBPM__Service_Request__c = SR.id  ;
        signedNOCCopySRDoc.Name ='Signed NOC Copy';
        signedNOCCopySRDoc.HexaBPM__Status__c ='Uploaded';
        srdocList.add(signedNOCCopySRDoc);
        
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test Content';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.Origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId =doaSRDoc.Id ;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM contentversion WHERE Id =: content.id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        /*HexaBPM__Step__c devNOCStep = new HexaBPM__Step__c();
devNOCstep.HexaBPM__SR__c = SR.Id;*/
        
        HexaBPM__Step_Template__c devNocStepTemplate = new HexaBPM__Step_Template__c();
        devNocStepTemplate.Name = 	'Issue NOC to Client';
        devNocStepTemplate.HexaBPM__Code__c = 'Issue NOC to Client';
        devNocStepTemplate.HexaBPM__Step_RecordType_API_Name__c = 'General';
        devNocStepTemplate.HexaBPM__Summary__c = 'Issue NOC to Client';
        insert devNocStepTemplate;
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Issued via Physically';
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = 'Issued via Physically';
        insert objStatus;
        
        HexaBPM__Step__c newStep = new HexaBPM__Step__c();
        newStep.HexaBPM__SR__c = SR.id;
        newStep.HexaBPM__Due_Date__c = System.Now().addDays(2);
        newStep.HexaBPM__Step_No__c = 10;
        newStep.HexaBPM__Status__c = objStatus.Id;
        //newStep.HexaBPM__SR_Step__c = objSRSteps.Id;
        newStep.HexaBPM__Step_Template__c = devNocStepTemplate.id;
        newStep.HexaBPM__Step_Notes__c = 'test';
        newStep.HexaBPM__Summary__c = 'Issue NOC to Client';
        
        insert newStep;
        
        //SR DOCS
        HexaBPM__Document_Master__c buyerPasspotDocMaster = new HexaBPM__Document_Master__c();
        buyerPasspotDocMaster.HexaBPM__Code__c = 'Buyer Passport Copy';
        buyerPasspotDocMaster.HexaBPM__Available_to_client__c = true;
        buyerPasspotDocMaster.AvailableForCustomer__c=true;
        insert buyerPasspotDocMaster;
        
        HexaBPM__SR_Doc__c buyerPasspotDocMasterSrDoc = new HexaBPM__SR_Doc__c();
        buyerPasspotDocMasterSrDoc.HexaBPM__Document_Master__c = buyerPasspotDocMaster.id  ;
        buyerPasspotDocMasterSrDoc.HexaBPM__Service_Request__c = SR.id  ;
        buyerPasspotDocMasterSrDoc.HexaBPM__Status__c = 'Uploaded';
        buyerPasspotDocMasterSrDoc.Name='Buyer Passport Copy' ;
       srdocList.add(buyerPasspotDocMasterSrDoc);
        insert srdocList;
        
    }
    @isTest
    static void validSRScenario(){
        Test.startTest();
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
        
        list<Unit__c> unitList =[SELECT Id FROM Unit__C LIMIT 1];
        
        list<HexaBPM__Service_Request__c> validServiceRequest =[SELECT Id FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c= 19500.01];
        
        String unitId = unitList[0].Id ;
        String sRId = validServiceRequest[0].Id ;
        string accountId = accountList[0].Id;
        
        String inputPayload = '{' + 
            '"customerId": "' + accountId + '",' +  
            '"unitId": "' + unitId + '",' +  
            '"sRId": "' + sRId + '",' +  
            '"SRType": "Property Transfer NOC",' +  
            '"hasUserProfileUpdated": true' +  
            '}';
        
        System.debug('inputPayload: ' + inputPayload);
        
        
        System.debug('inputPayload: ' + inputPayload);
        
        //Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/GetNOC';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerGetNocDetailsWebService.getNOCDetails();
        Test.stopTest();
        
        
    }
    @isTest
    static void jbDocExpiry(){
        
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'testjbAcc@gmail.com'];
        
        list<Unit__c> unitList =[SELECT Id FROM Unit__C LIMIT 1];
        Test.startTest();
        list<HexaBPM__Service_Request__c> validServiceRequest =[SELECT Id FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c= 19500.01];
        
        String unitId = unitList[0].Id ;
        String sRId = validServiceRequest[0].Id ;
        string accountId = accountList[0].Id;
        
        String inputPayload = '{' + 
            '"customerId": "' + accountId + '",' +  
            '"unitId": "' + unitId + '",' +  
            '"sRId": "' + sRId + '",' +  
            '"SRType": "Property Transfer NOC",' +  
            '"hasUserProfileUpdated": true' +  
            '}';
        
        System.debug('inputPayload: ' + inputPayload);
        
        
        System.debug('inputPayload: ' + inputPayload);
        
        //Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/GetNOC';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerGetNocDetailsWebService.getNOCDetails();
        Test.stopTest();
        
        
    }
    @isTest
    static void invalidSRScenario(){
        
        list<Unit__c> unitLists =[SELECT Id FROM Unit__C LIMIT 1];
        Test.startTest();
        list<HexaBPM__Service_Request__c> inValidServiceRequest =[SELECT Id FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c =:19501.01];
        String inputPayload = '{' + 
            '"customerId": "001FV000003oNZUYA2",' +
            '"unitId": "' + String.valueOf(unitLists[0].Id) + '",' +  
            '"sRId":  "001FV000003oNZUYA2",' +  
            '"SRType": "Property Transfer NOC"' +
            '}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/GetNOC';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerGetNocDetailsWebService.getNOCDetails();
        Test.stopTest();
    }
    @isTest
    static void catchExceptionMethod(){
        
        list<Unit__c> unitListCEM =[SELECT Id FROM Unit__C LIMIT 1];
        Test.startTest();
        list<HexaBPM__Service_Request__c> ServiceRequestCEM =[SELECT Id FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c=:19500.01];
        
        String inputPayload = '{' + 
            '"customerId": "001FV000003oNZUYA2",' +
            '"unitId":'+unitListCEM[0].Id+ ',' +
            '"sRId":'+ServiceRequestCEM[0].Id+',' +
            '"SRType": "Property Transfer NOC"' +
            '}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/GetNOC';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerGetNocDetailsWebService.getNOCDetails();
        Test.stopTest();
        
        
    }
    
    
    
}