@isTest
public class MobileMockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        
        // Simulate a response based on your expected result
        Map<String, String> mockResponse = new Map<String, String>{
            'IsValid' => 'ExpectedIsValid',
            'NationalFormat' => '0 971 123 4567',
               'CountryPrefix' => '971'
        };
        
        res.setBody(JSON.serialize(mockResponse));
        res.setStatusCode(200); // Set the desired status code
        
        return res;
    }
}