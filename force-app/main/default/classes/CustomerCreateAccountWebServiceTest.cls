@isTest
public class CustomerCreateAccountWebServiceTest {
    @testSetUp
    static void dataSetUp(){
        
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert acc;
        
        Account nonExistingAcc = new Account();
        nonExistingAcc.FirstName='Test';
        nonExistingAcc.LastName= 'Drogo';
        nonExistingAcc.PersonEmail='drogo@gmail.com';
        nonExistingAcc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert nonExistingAcc;
        
        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c();
        submittedStatus=TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        
        HexaBPM__SR_Status__c cancelledStatus = new HexaBPM__SR_Status__c();
        cancelledStatus=TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelledStatus;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        list<Unit__c> unitList = new list<unit__c>();
        unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Name = 'Test MAYAN-B1-1004'; 
        unit2.Project__c= project.Id;
        insert unit2;
        
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        
        HexaBPM__Service_Request__c srExists=TestObjectsFactory.getServiceRequest(submittedStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c=19500.01;
        srExists.HexaBPM__Customer__c=acc.Id;
        insert srExists;
        system.debug('Existing SR::'+ srExists);
        
        HexaBPM__Service_Request__c srNotExist=TestObjectsFactory.getServiceRequest(cancelledStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srNotExist.TransferSellingPrice__c=19501.01;
        insert srNotExist;
        
    }
    
    @isTest
    static void srAccExists(){
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
        list<Unit__c> unitList =[SELECT Id FROM Unit__C LIMIT 1];
        
        List<HexaBPM__Service_Request__c> existingSRs = [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE Unit__c =:unitList[0].Id AND HexaBPM__Customer__c = :accountList[0].Id AND SRType__c ='Property Transfer NOC' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled')];
        
        String jsonString = '{' +
            '"firstName": "Test",' +
            '"lastName": "Agnii Doc generation",' +
            '"email": "agni@gmail.com",' +
            '"mobileCountryCode": "91",' +
            '"mobilePhone": "790763278011",' +
            '"BuyerList": [' +
            '{' +
            '"firstname": "TestBuyer",' +
            '"lastname": "BuyerLastname",' +
            '"email": "buyer@yopmail.com",' +
            '"mobileCountryCode": "1",' +
            '"mobilePhone": "9876543210",' +
            '"isPrimary": true' +
            '}' +
            '],' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "a2A8d000000LfFAEA0",' +
            '"transferSellingPrice": "19500.01",' +
            '"unusedServiceCharge": "19500.0",' +
            '"hasOwnerNOCExist": true,' +
            '"referenceId": "testagnifi4@yopmail.com"' +
            '}';
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createAccount';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(jsonString);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreateAccountWebService.createAccount();
        Test.stopTest();
        
    }
    @isTest
    static void srAccNotExists(){
        
        list<Unit__c> unitList =[SELECT Id FROM Unit__C WHERE name ='Test MAYAN-B1-1004' LIMIT 1];
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
        
        
        String jsonString = '{' +
            '"firstName": "Test",' +
            '"lastName": "Agnii Doc generation",' +
            '"email": "agni@gmail.com",' +
            '"mobileCountryCode": "91",' +
            '"mobilePhone": "790763278011",' +
            '"BuyerList": [' +
            '{' +
            '"firstname": "TestBuyer",' +
            '"lastname": "BuyerLastname",' +
            '"email": "buyer@example.com",' +
            '"mobileCountryCode": "1",' +
            '"mobilePhone": "9876543210",' +
            '"isPrimary": true' +
            '}' +
            '],' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "a2A8d000000LfFAEA0",' +
            '"transferSellingPrice": "19500.01",' +
            '"unusedServiceCharge": "19500.0",' +
            '"hasOwnerNOCExist": true,' +
            '"referenceId": "testagnifi4@yopmail.com"' +
            '}';
        
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createAccount';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(jsonString);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreateAccountWebService.createAccount();
        Test.stopTest();
        
        
    }
    @isTest
    static void catchException(){
        list<Unit__c> unitList =[SELECT Id FROM Unit__C LIMIT 1];
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
        
        String jsonString = '{' +
            '"buyerType": "Individual",' +
            '"firstname": "Test",' +
            '"lastname": "Agnii",' +
            '"email": "test@yopmail.com",' +
            '"mobilePhone": "790763276545",' +
            '"mobileCountryCode": "91",' +
            '"referenceId": "agni@gmail.com",' +
            '"customerId":'+accountList[0].Id+ ',' +
            '"unitId":'+unitList[0].Id+ ',' +
            '"salesOrderId": "a2A8d000000LfFAEA0",' +
            '"transferSellingPrice": "19500.01",' +
            '"unusedServiceCharge": "19500.0",' +
            '"hasOwnerNOCExist": "true" ' +
            '}';
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createAccount';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(jsonString);
        RestContext.request = req;
        RestContext.response = res;
        //CustomerCreateAccountWebService.createAccount();
        Test.stopTest();
        
    }
    
}