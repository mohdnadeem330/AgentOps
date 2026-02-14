@isTest
public class BP_BaseRestResourceTest {

    public class MockRestResource extends BP_BaseRestResource {
        
        public override BP_BaseRestResource.ApiResponse processRequest(Map<String, String> params, String requestBody) {
            return new BP_BaseRestResource.ApiResponse(true, 200, 'Request processed successfully', new Map<String, Object>{'key' => 'value'});
        }
    }

    @isTest
    static void testProcessRequest() {
        MockRestResource resource = new MockRestResource();
        Map<String, String> params = new Map<String, String>{'param1' => 'value1'};
        String requestBody = '{"key": "value"}';
        
        BP_BaseRestResource.ApiResponse response = resource.processRequest(params, requestBody);
        
        System.assertEquals(true, response.success, 'Success should be true');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('Request processed successfully', response.message, 'Message should match');
        System.assert(response.data != null, 'Data should not be null');
    }

    @isTest
    static void testHandleException() {
        Exception testException = new NullPointerException();  
        
        BP_BaseRestResource.ApiResponse response = BP_BaseRestResource.handleException(testException, 500);
        
        System.assertEquals(false, response.success, 'Success should be false');
        System.assertEquals(500, response.statusCode, 'Status code should be 500');
        System.assert(response.message.contains('Error'), 'Error message should contain "Error"');
        System.assert(response.data == null, 'Data should be null in case of error');
    }

    @isTest
    static void testParseRequestBody() {
        String body = '{"key": "value"}';
        
        Map<String, Object> parsedBody = BP_BaseRestResource.parseRequestBody(body);
        
        System.assertEquals(1, parsedBody.size(), 'Parsed body should have one key-value pair');
        System.assertEquals('value', parsedBody.get('key'), 'Value for "key" should be "value"');
    }

    @isTest
    static void testParseRequestBodyEmpty() {
        String body = '';
        
        Map<String, Object> parsedBody = BP_BaseRestResource.parseRequestBody(body);
    }
}