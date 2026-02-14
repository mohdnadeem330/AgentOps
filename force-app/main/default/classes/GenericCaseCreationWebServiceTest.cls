@isTest
private class GenericCaseCreationWebServiceTest {
    
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
    }

    @isTest
    static void testCreateCaseSuccess() {
        
        Unit__c unit = [Select Id from Unit__c where Name = 'MAYAN-B2-2004' limit 1];
        Account account = [Select Id from Account where PersonEmail = 'agniMoveOut@gmail.com' limit 1];
        // Prepare test JSON payload with valid fields including RecordTypeName
        String recordTypeName = 'Standard Case'; // Change this to an actual RecordType Name in your org or create one in test setup

        // Retrieve actual RecordTypeId for the test1
        Id recordTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        if(rtMap.containsKey(recordTypeName)) {
            recordTypeId = rtMap.get(recordTypeName).getRecordTypeId();
        } else {
            // Create a record type in test context if necessary (usually not allowed but just for example)
            // Or use the default record type or null if none
            recordTypeId = null;
        }
        
        Case newCase = new case();
        newCase.Description = 'Test';
        newCase.Unit__c = unit.Id;
        newCase.RecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Complaint')).getRecordTypeId();
        newCase.Type = 'Other Requests';
        newCase.ServiceCloudCaseNumber__c = 'Test';
        
        insert newCase;
        

        Map<String, Object> casePayload = new Map<String, Object>{
            'RecordTypeName' => 'ECSS Complaint',
            'Description' => 'Test Case Subject',
            'Unit__c' => unit.Id,
            'Type' => 'Other Requests',
            'ServiceCloudCaseNumber__c' => 'Test',
            'operation' => 'create'
        };

        String jsonBody = JSON.serialize(casePayload);

        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/GenericCaseAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        GenericCaseCreationWebService.createCase();
        GenericCaseCreationWebService.getCaseDetails(new List<Case>{newCase});
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

    }

    @isTest
    static void testCreateCaseWithInvalidField() {
        // Payload includes a field that is not on Case to test graceful handling
        Map<String, Object> casePayload = new Map<String, Object>{
            'Subject' => 'Test Case Subject',
            'InvalidField' => 'Some Value' // Should be ignored
        };

        String jsonBody = JSON.serialize(casePayload);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/GenericCaseAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        GenericCaseCreationWebService.createCase();
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseException() {
        // Passing invalid JSON to force exception
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/GenericCaseAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid JSON');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        GenericCaseCreationWebService.createCase();
        GenericCaseCreationWebService.getCaseDetails(new List<Case>{new Case()});
        Test.stopTest();

    }
    
    @isTest
    static void testCancelCaseSuccess() {
        
        Unit__c unit = [Select Id from Unit__c where Name = 'MAYAN-B2-2004' limit 1];
        Account account = [Select Id from Account where PersonEmail = 'agniMoveOut@gmail.com' limit 1];
        // Prepare test JSON payload with valid fields including RecordTypeName
        String recordTypeName = 'Standard Case'; // Change this to an actual RecordType Name in your org or create one in test setup

        // Retrieve actual RecordTypeId for the test
        Id recordTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        if(rtMap.containsKey(recordTypeName)) {
            recordTypeId = rtMap.get(recordTypeName).getRecordTypeId();
        } else {
            // Create a record type in test context if necessary (usually not allowed but just for example)
            // Or use the default record type or null if none
            recordTypeId = null;
        }
        
        Case newCase = new case();
        newCase.Description = 'Test';
        newCase.Unit__c = unit.Id;
        newCase.RecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Complaint')).getRecordTypeId();
        newCase.Type = 'Other Requests';
        newCase.ServiceCloudCaseNumber__c = 'Test';
        
        insert newCase;
        

        Map<String, Object> casePayload = new Map<String, Object>{
            'entityId' => newCase.Id,
            'operation' => 'cancel'
        };

        String jsonBody = JSON.serialize(casePayload);

        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/GenericCaseAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        GenericCaseCreationWebService.createCase();
        Test.stopTest();
    }
    
    @isTest
    static void testGetCaseSuccess() {
        
        Unit__c unit = [Select Id from Unit__c where Name = 'MAYAN-B2-2004' limit 1];
        Account account = [Select Id from Account where PersonEmail = 'agniMoveOut@gmail.com' limit 1];
        // Prepare test JSON payload with valid fields including RecordTypeName
        String recordTypeName = 'Standard Case'; // Change this to an actual RecordType Name in your org or create one in test setup

        // Retrieve actual RecordTypeId for the test
        Id recordTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        if(rtMap.containsKey(recordTypeName)) {
            recordTypeId = rtMap.get(recordTypeName).getRecordTypeId();
        } else {
            // Create a record type in test context if necessary (usually not allowed but just for example)
            // Or use the default record type or null if none
            recordTypeId = null;
        }
        
        Case newCase = new case();
        newCase.Description = 'Test';
        newCase.Unit__c = unit.Id;
        newCase.RecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Complaint')).getRecordTypeId();
        newCase.Type = 'Other Requests';
        newCase.ServiceCloudCaseNumber__c = 'Test';
        
        insert newCase;
        

        Map<String, Object> casePayload = new Map<String, Object>{
            'operation' => 'get',
            'Type' => 'Other Requests',
            'Unit__c' => unit.Id
        };

        String jsonBody = JSON.serialize(casePayload);

        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/GenericCaseAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        GenericCaseCreationWebService.createCase();
        Test.stopTest();

    }

}