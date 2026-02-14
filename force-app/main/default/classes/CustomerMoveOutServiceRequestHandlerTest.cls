@isTest 
public class CustomerMoveOutServiceRequestHandlerTest {

    @testSetUp
    static void dataSetUp() {
        Id personAccountRecordTypeId = Utilities.getRecordTypeId('Account', 'Person Account');
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Agni',
            PersonEmail = 'agniMoveOut@gmail.com',
            RecordTypeId = personAccountRecordTypeId,
            CustomerAppWebUser__c = false
        );
        insert acc;

        Project__c project = TestObjectsFactory.getProjectRecord('recordId');
        project.OA_Community_Name__c = 'Al Raha Beach';
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B2-2004';
        unit.Project__c = project.Id;
        insert unit;

        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Status__c = 'Sold';
        unit2.Name = 'ALG2-B2-2005';
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

        Id moveOutNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'AldarEstatesMoveOut');
        HexaBPM__SR_Template__c moveOutSRTemplate = new HexaBPM__SR_Template__c(
            HexaBPM__Active__c = true,
            HexaBPM__SR_RecordType_API_Name__c = 'AldarEstatesMoveOut'
        );
        insert moveOutSRTemplate;

        HexaBPM__Service_Request__c moveOutSR = TestObjectsFactory.getServiceRequest(
            submittedStatus.Id, unit.Id, 'Aldar Estates Move-Out', moveOutNOCRTId, moveOutSRTemplate.Id
        );
        moveOutSR.HexaBPM__Customer__c = acc.Id;
        moveOutSR.RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AldarEstatesMoveOut').getRecordTypeId();
        insert moveOutSR;
    }

    @isTest
    static void moveOutSrCreate() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agniMoveOut@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];

        String jsonString = '{' +
            '"srType": "Aldar Estates Move Out",' +
            '"origin": "Customer Portal",' +
            '"operation": "create",' +
            '"requestDetails": {' +
                '"moveOutDate": "2025-01-30",' +
                '"moveOutTime" : "10:00:00",' +
                '"additionalInfo": "MoveOut testing"' +
            '},' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "SO-001"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }
    
    @isTest
    static void moveOutSrCreateSR() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agniMoveOut@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c where Name = 'ALG2-B2-2005'];

        String jsonString = '{' +
            '"srType": "Aldar Estates Move Out",' +
            '"origin": "Customer Portal",' +
            '"operation": "create",' +
            '"requestDetails": {' +
                '"moveOutDate": "2025-01-30",' +
                '"moveOutTime" : "11:00:00",' +
                '"additionalInfo": "Second SR test"' +
            '},' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"salesOrderId": "a2A8d000000LfFAEA0"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res;
        CustomerMoveOutServiceRequestHandler.MoveOutServiceRequestPayload movePayload = new CustomerMoveOutServiceRequestHandler.MoveOutServiceRequestPayload('Get','','', '', new CustomerMoveOutServiceRequestHandler.RequestDetails(Date.today(),''));

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }

    @isTest
    static void moveOutSrGet() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agniMoveOut@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c where Name = 'MAYAN-B2-2004'];

        String jsonStringGet = '{' +
            '"srType": "Aldar Estates Move Out",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "get"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringGet);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }

    @isTest
    static void moveOutSrGetById() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agniMoveOut@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];
        List<HexaBPM__Service_Request__c> srList = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];

        String jsonStringGet = '{' +
            '"srType": "Aldar Estates Move Out",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "get",' +
            '"srId": "' + srList[0].Id + '"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringGet);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }

    @isTest
    static void moveOutSrCancel() {
        List<Account> accountList = [SELECT Id FROM Account WHERE PersonEmail = 'agniMoveOut@gmail.com'];
        List<Unit__c> unitList = [SELECT Id FROM Unit__c LIMIT 1];

        String jsonStringCancel = '{' +
            '"srType": "Aldar Estates Move Out",' +
            '"origin": "Customer Portal",' +
            '"customerId": "' + accountList[0].Id + '",' +
            '"unitId": "' + unitList[0].Id + '",' +
            '"operation": "cancel"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonStringCancel);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }

    @isTest
    static void testExceptionBlock() {
        String invalidJson = '{"badJson::"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/moveOutService';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(invalidJson);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerMoveOutServiceRequestHandler.MoveOut();
        Test.stopTest();
    }  


    
}