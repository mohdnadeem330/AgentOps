@isTest
    public class BP_NewsAndAnnouncementsTest {
    
        
        @IsTest
        static void testExecute_invalidRequestBody() {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getNewsAndAnnouncements';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueOf(''); // Empty body
    
            RestContext.request = req;
            RestContext.response = new RestResponse();
    
            Test.startTest();
           BP_NewsAndAnnouncements.execute();
            Test.stopTest();
    
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
            System.assertEquals(false, response.get('success'), 'The response should indicate failure');
            System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
        }
    
        @isTest
        static void testProcessRequestFailure() {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestBody = Blob.valueOf('Invalid JSON');  // Malformed JSON
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/getNewsAndAnnouncements';
            
            RestContext.request = req;
            RestContext.response = res;
    
            Test.startTest();
            BP_NewsAndAnnouncements.execute();
            Test.stopTest();
    
            /*BP_BaseRestResource.ApiResponse apiResponse = 
                (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                    RestContext.response.responseBody.toString(),
                    BP_BaseRestResource.ApiResponse.class
                );
    
            System.assertNotEquals(null, apiResponse, 'API response should not be null');
            System.assertEquals(400, apiResponse.statusCode, 'API status code should be 400');
            System.assert(apiResponse.message.contains('Failed to fetch News and announcements'), 'API message should indicate failure');*/
        }
    
        @isTest
        static void testExecute_withExceptionInCatchBlock() {
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/getNewsAndAnnouncements';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueOf('{"malformedJson": '); // Malformed JSON
    
            RestContext.request = req;
            RestContext.response = new RestResponse();
    
            Test.startTest();
            BP_NewsAndAnnouncements.execute();
            Test.stopTest();
    
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
            System.assert(response.get('message') != null, 'The error message should not be null');
        }
    
        @isTest
        static void testExecute_withCatchBlockHandled() {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getNewsAndAnnouncements';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
    
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('invalidField', 'SomeValue'); // Invalid field
            req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
    
            RestContext.request = req;
            RestContext.response = new RestResponse();
    
            Test.startTest();
            BP_NewsAndAnnouncements.execute();
            Test.stopTest();
    
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
            System.assert(response.get('message') != null, 'The error message should not be null');
        }
    
        @isTest
        static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/getNewsAndAnnouncements';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
    
            req.requestBody = null;  // Null body to test failure
            RestContext.request = req;
            RestContext.response = new RestResponse();
    
            Test.startTest();
            try {
                BP_NewsAndAnnouncements.execute();
            } catch (Exception e) {
                System.debug('Exception caught: ' + e.getMessage());
            }
            Test.stopTest();
    
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
            System.assertEquals(false, response.get('success'), 'Success should be false for invalid request.');
        }
        @isTest(SeeAllData=true)
        static void testExecuteWithValidRequestBody() {
            String requestBody = JSON.serialize(new Map<String, Object> {
                'page' => 0,
                'pageSize' => 25,
                'language' => 'en_US',
                'filterby' => 'Aldar_NewsAnnouncements',
                'year' => '2024',
                'month' => '02',
                'searchKey' => 'test'
            });
    
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/getNewsAndAnnouncements';
            
            RestContext.request = req;
            RestContext.response = res;
    
            Test.startTest();
            BP_NewsAndAnnouncements.execute();
            Test.stopTest();
    
           /* BP_BaseRestResource.ApiResponse apiResponse = 
                (BP_BaseRestResource.ApiResponse) JSON.deserialize(
                    RestContext.response.responseBody.toString(),
                    BP_BaseRestResource.ApiResponse.class
                );
            System.assertEquals(200, response.statusCode);*/
               }
    
      
    }