@isTest
private class TenantSelfCreateAccountWebServiceTest {
    
    @testSetUp
    static void dataSetUp() { 
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'abc@gmail.com';
        insert personAcc;  
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.ADMBuildingNumber__c = 'Test';
        unit.ADMPlotNumber__c = 'Test';
        unit.ADMUnitNumber__c = 'Test';
        insert unit;
    }
    
    @isTest
    static void testCreateTenantSelfAccount() {
        
        Account newAccount = [select id,PersonEmail  from Account limit 1];
        
        system.debug('newAccount-->'+newAccount);
        Unit__c unit = [Select Id,ADMBuildingNumber__c,ADMPlotNumber__c,ADMUnitNumber__c from Unit__c limit 1];
        
        
        system.debug('newAccount-->'+newAccount);
        
        Map<String, Object> tenantPayload = new Map<String, Object>{
            'firstName' => 'Test',
                'lastName' => 'Test',
                'email' =>'xyz@gmail.com' ,
                'ADMBuildingNumber' => unit.ADMBuildingNumber__c,
                'ADMPlotNumber' => unit.ADMPlotNumber__c,
                'ADMUnitNumber' => unit.ADMUnitNumber__c
                };
                    
                    String jsonBody = JSON.serialize(tenantPayload);
        
        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/customer/createTenantSelfAccount';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        TenantSelfCreateAccountWebService.createTenantSelfAccount();
        Test.stopTest();
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        
    }
    
    @isTest
    static void testCreateTenantSelfExistingAccount() {
        
        Account newAccount = [select id,PersonEmail  from Account limit 1];
        
        
        Unit__c unit = [Select Id,ADMBuildingNumber__c,ADMPlotNumber__c,ADMUnitNumber__c from Unit__c limit 1];
        
        
        system.debug('newAccount-->'+newAccount);
        
        Map<String, Object> tenantPayload = new Map<String, Object>{
            'firstName' => 'Test',
                'lastName' => 'Test',
                'email' => newAccount.PersonEmail ,
                'ADMBuildingNumber' => unit.ADMBuildingNumber__c,
                'ADMPlotNumber' => unit.ADMPlotNumber__c,
                'ADMUnitNumber' => unit.ADMUnitNumber__c
                };
                    
                    String jsonBody = JSON.serialize(tenantPayload);
        
        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/customer/createTenantSelfAccount';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        TenantSelfCreateAccountWebService.createTenantSelfAccount();
        Test.stopTest();
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        
    }
}