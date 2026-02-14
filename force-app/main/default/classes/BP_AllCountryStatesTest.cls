@isTest
public class BP_AllCountryStatesTest {

  
    @isTest
    static void testDoGetWithNoParams() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/countryStatePicklist';
        req.httpMethod = 'GET';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        BP_AllCountryStates.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Expected status code 200');
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('Success'), 'Response should contain Success');
        System.assert(body.contains('countriesAndStates'), 'Response should contain country/state map');
    }

    
    @isTest
    static void testDoGetWithCountryParam() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/countryStatePicklist?country=United States';
        req.httpMethod = 'GET';
        req.params.put('country', 'United States');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        BP_AllCountryStates.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('Success'));
        System.assert(body.contains('countriesAndStates'));
    }

    
    @isTest
    static void testProcessRequestDirect() {
        BP_AllCountryStates api = new BP_AllCountryStates();
        Map<String,String> params = new Map<String,String>();

        Test.startTest();
        Object respObj = api.processRequest(params, '');
        Test.stopTest();

        
        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(respObj));

        System.assertEquals(200, (Integer)resp.get('statusCode'));
        System.assertEquals(true, (Boolean)resp.get('success'));
        System.assertNotEquals(null, resp.get('data'));
    }

   
    @isTest
    static void testProcessRequestWithCountry() {
        BP_AllCountryStates api = new BP_AllCountryStates();
        Map<String,String> params = new Map<String,String>{ 'country' => 'United States' };

        Test.startTest();
        Object respObj = api.processRequest(params, 'dummyBody');
        Test.stopTest();

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(respObj));

        System.assertEquals(200, (Integer)resp.get('statusCode'));
        System.assertEquals(true, (Boolean)resp.get('success'));
        System.assertNotEquals(null, resp.get('data'));
    }


    @isTest
    static void testProcessRequestException() {
        BP_AllCountryStates api = new BP_AllCountryStates();

        Test.startTest();
        Object respObj = api.processRequest(null, null); 
        Test.stopTest();

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(respObj));

        System.assertEquals(500, (Integer)resp.get('statusCode'), 'Should return 500');
        System.assertEquals(false, (Boolean)resp.get('success'), 'Success should be false');
    }

    
    @isTest
    static void testGetDependentPicklistValues() {
        Test.startTest();
        Map<String, List<String>> result = BP_AllCountryStates.getDependentPicklistValues(User.StateCode);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a non-null map');
    }

   
    //@isTest
    //static void testGetDependentPicklistValuesException() {
        //Test.startTest();
        //Map<String, List<String>> result = BP_AllCountryStates.getDependentPicklistValues(null);
        //Test.stopTest();

        //System.assertNotEquals(null, result, 'Even on exception, should return non-null');
        //System.assertEquals(true, result.isEmpty(), 'On exception should return empty map');
    //}
}