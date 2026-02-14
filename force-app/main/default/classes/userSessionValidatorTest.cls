@isTest
public class userSessionValidatorTest {
    @isTest
    static void testValidUserId() {
        // Mocking the HTTP request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/usersessionvalidator';
        request.addParameter('userid', 'validUserId');
        
        RestContext.request = request;
        
        // Mocking the HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Call the REST service method
        Test.startTest();
        userSessionValidator.doPost();
        Test.stopTest();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }
    
    @isTest
    static void testMissingUserId() {
        // Mocking the HTTP request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/usersessionvalidator';
        
        RestContext.request = request;
        
        // Mocking the HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Call the REST service method
        Test.startTest();
        userSessionValidator.doPost();
        Test.stopTest();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
    }
}