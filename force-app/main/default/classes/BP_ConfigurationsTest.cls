@isTest
private class BP_ConfigurationsTest {
    
    @isTest
    static void testExecute() {
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getConfigurations';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_Configurations.execute();
        
        RestResponse res = RestContext.response;
        System.assert(res.responseBody != null);
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRequest() {
        Test.startTest();
        
        Map<String, String> params = new Map<String, String>();
        params.put('param1', 'value1');
        params.put('param2', 'value2');
        
        BP_Configurations service = new BP_Configurations();
        BP_BaseRestResource.ApiResponse apiResponse = service.processRequest(params, null);
        
        System.assertNotEquals(apiResponse, null);
        System.assertEquals(apiResponse.statusCode, 200);
        System.assertEquals(apiResponse.message, 'Data fetched successfully');
        System.assertNotEquals(apiResponse.data, null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetConfigurations() {
        Test.startTest();
        
        BP_Configurations.ConfigurationsResponse response = BP_Configurations.getConfigurations();
        
        System.assertNotEquals(response, null);
        System.assertNotEquals(response.leadSource, null);
        System.assertNotEquals(response.salesOrigin, null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetLeadPicklistValues() {
        Test.startTest();
        
        BP_Configurations.ConfigurationsResponse response = new BP_Configurations.ConfigurationsResponse();
        
        BP_Configurations.getLeadPicklistValues(response);
        
        System.assertNotEquals(response.leadSource, null);
        System.assertNotEquals(response.salesOrigin, null);
        System.assertNotEquals(response.salesType, null);
        
        Test.stopTest();
    }

    @isTest
    static void testGetCasePicklistValues() {
        Test.startTest();
        
        BP_Configurations.ConfigurationsResponse response = new BP_Configurations.ConfigurationsResponse();
        
        BP_Configurations.getCasePicklistValues(response);
        
        System.assertNotEquals(response.categoryList, null);
        
        Test.stopTest();
    }
}