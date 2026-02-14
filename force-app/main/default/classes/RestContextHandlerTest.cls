@isTest
private class RestContextHandlerTest {

    static testMethod void InitialTest() {
        
        TestObjectsFactory.initializeRestContext('body', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        
        RestContextHandler handler = new RestContextHandler(true);
        handler.finalize();
        
        Id requestId = handler.response.requestId;
       
        Logger__c log = [SELECT ResourcePath__c, Id, AppVersion__c, DeviceOS__c, DeviceOSVersion__c, DeviceModel__c 
        FROM Logger__c
        WHERE Id =: requestId];
        
        System.assertequals(log.Id, requestId);
        System.assertequals(log.AppVersion__c, '1.0');
        System.assertequals(log.DeviceOS__c, 'ios');
        System.assertequals(log.DeviceOSVersion__c, '12.1');
        System.assertequals(log.DeviceModel__c, 'iphone x');
        System.assertequals(log.ResourcePath__c, '/some/path');
        
        Exception exc = new SObjectException();
        handler.finalize(exc);
        
        Logger__c updatedLog = [SELECT StackTrace__c, Id, AppVersion__c, DeviceOS__c, DeviceOSVersion__c, DeviceModel__c 
        FROM Logger__c
        WHERE Id =: requestId];
        
        System.assertNotEquals(updatedLog.StackTrace__c, null);
        
    }

    static testMethod void requestBodyTest() {
        
        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('Key', 'Value');
        String jsonBody = JSON.serialize(bodyMap);
        
        TestObjectsFactory.initializeRestContext(jsonBody, '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        
        RestContextHandler handler = new RestContextHandler(false);

        handler.getRequestBodyMap();
        handler.setResponseBody(Blob.valueOf(jsonBody));
        handler.addResponseHeader('X-Custom-Header', 'Value');
        handler.setResponseStatusCode(200);
        handler.finalize();

        try {
            Integer i = 1/0;
        }
        catch(Exception exc) {
            handler.finalize(exc);
        }
    }

    static testMethod void requestRequestObjectMapTest() {

        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('Key', 'Value');
        String jsonBody = JSON.serialize(bodyMap);
        
        TestObjectsFactory.initializeRestContext(jsonBody, '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        
        RestContextHandler handler = new RestContextHandler(false);

        handler.getRequestBodyMapObject();
        handler.finalize();
    }

    static testMethod void requestEmptyBodyTest() {

        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);

        handler.getRequestBodyMap();
        handler.getRequestBodyMapObject();
        handler.finalize();
    }

    static testMethod void requestInvalidBodyTest() {

        try {
            TestObjectsFactory.initializeRestContext('a', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
            RestContextHandler handler = new RestContextHandler(false);

            handler.getRequestBodyMap();
            handler.finalize();
        }
        catch(Exception exc) {}
    }

    static testMethod void requestInvalidBodyObjectTest() {

        try {
            TestObjectsFactory.initializeRestContext('a', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
            RestContextHandler handler = new RestContextHandler(false);

            handler.getRequestBodyMapObject();
            handler.finalize();
        }
        catch(Exception exc) {}
    }
    
    static testMethod void InvalidRestServiceTest() {
        
        try {
            RestContextHandler handler = new RestContextHandler(true);
        }
        catch (Exception e) {
            
            System.assertequals(e.getTypeName(), 'RestContextHandler.RestException');   
        }
    }

    static testMethod void evaluateAllowedAppVersionTest() {
        
        TestObjectsFactory.initializeRestContext('a', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        RestContextHandler handler = new RestContextHandler(true);
        handler.evaluateAppVersionForAllowed();
    }

    static testMethod void evaluateLatestAppVersionTest() {
        
        TestObjectsFactory.initializeRestContext('a', '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        RestContextHandler handler = new RestContextHandler(true);
        handler.evaluateAppVersionForLatest();
    }
}