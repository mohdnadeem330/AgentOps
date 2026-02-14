@isTest
//testemoji 
public class CustomerMoveInServiceRequestHandlerTest {
    @testSetUp
    static void dataSetUp() {
        Id personAccountRecordTypeId = utilities.getRecordTypeId('Account', 'Person Account');
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Agni',
            PersonEmail = 'agni@gmail.com',
            RecordTypeId = personAccountRecordTypeId,
            CustomerAppWebUser__c = false
        );
        insert acc;

        Project__c project = TestObjectsFactory.getProjectRecord('recordId');
        project.OA_Community_Name__c = 'Al Muneera';
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004';
        unit.Project__c = project.Id;
        insert unit;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Name = 'ALG2-B1-1004';
        unit2.Project__c = project.Id;
        insert unit2;

        HexaBPM__SR_Status__c submittedStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        
		HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Cancelled';
        status.HexaBPM__Code__c = 'Cancelled';
        status.HexaBPM__Type__c = 'Start';
        insert status;
        
         HexaBPM__SR_Status__c cancelledByuser = new HexaBPM__SR_Status__c();
         cancelledByuser.Name = 'Cancelled By user';
        cancelledByuser.HexaBPM__Code__c = 'Cancelled By user';
        insert cancelledByuser;

        Id moveInNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'AldarEstatesMoveInOut');
        HexaBPM__SR_Template__c moveInSRTemplate = new HexaBPM__SR_Template__c(
            HexaBPM__Active__c = true,
            HexaBPM__SR_RecordType_API_Name__c = 'Aldar Estates Move In/Out'
        );
        insert moveInSRTemplate;

        HexaBPM__Service_Request__c moveInSR = TestObjectsFactory.getServiceRequest(
            submittedStatus.Id, unit.Id, 'Aldar Estates Move-In', moveInNOCRTId, moveInSRTemplate.Id
        );
        moveInSR.HexaBPM__Customer__c = acc.Id;
        moveInSR.RecordTypeId =  Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AldarEstatesMoveInOut').getRecordTypeId();
        
        insert moveInSR;
        system.debug('INSERTED_SR_DETAILS::'+moveInSR);
    }

    @isTest
    static void moveInSrCreate() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];

        String jsonString = '{' +
            '"srType": "Aldar Estates Move In",' +
            '"origin": "Customer Portal",' +
            '"operation": "create",' +
            '"requestDetails": {' +
                '"moveInDate": "2025-01-15",' +
            	'"moveInTime" : "14:30:00",'+
                '"additionalInfo": "testee"' +
            '},' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "a2A8d000000LfFAEA0"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }
    
    @isTest
    static void moveInSrCreateSR() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c where name = 'ALG2-B1-1004' ];

        String jsonString = '{' +
            '"srType": "Aldar Estates Move In",' +
            '"origin": "Customer Portal",' +
            '"operation": "create",' +
            '"requestDetails": {' +
                '"moveInDate": "2025-01-15",' +
            	'"moveInTime" : "14:30:00",'+
                '"additionalInfo": "testee"' +
            '},' +
            '"customerId": "' + accountList[0].Id + '",' +
             '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "a2A8d000000LfFAEA0"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }

    @isTest
    static void moveInSrGet() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c  where name = 'ALG2-B1-1004'];

        String jsonStringGet = '{' +
            '"srType": "Aldar Estates Move In",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "get"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringGet);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }
	
    @isTest
    static void moveInSrGetExists() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];

        String jsonStringGet = '{' +
            '"srType": "Aldar Estates Move-In",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "get"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringGet);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }
    
    @isTest
    static void moveInSrGetSRId() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];
        list<HexaBPM__Service_Request__c> moveInSr= [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];

        String jsonStringGet = '{' +
            '"srType": "Aldar Estates Move-In",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "get",' +
            '"srId": "' + moveInSr[0].Id + '"' +
            '}';


        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringGet);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }

    @isTest
    static void moveInSRcancel() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c  where name = 'ALG2-B1-1004'];

        String jsonStringCancel = '{' +
            '"srType": "Aldar Estates Move In",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "cancel"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringCancel);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }

     @isTest
    static void moveInSRcancelExists() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agni@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];

        String jsonStringCancel = '{' +
            '"srType": "Aldar Estates Move-In",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "cancel"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringCancel);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }

    @isTest
    static void testExceptionBlock() {
        // Send invalid JSON to hit the catch block
        String invalidJson = '{"invalidJson::"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveInService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(invalidJson);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveInServiceRequestHandler.createAccount();
        Test.stopTest();
    }

}