@IsTest
public class CongaMockHttpResponseGenerator implements HttpCalloutMock {
    
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();
        String reqBody = req.getBody();

        // 1. Mock Salesforce and Conga Authentication (Covers both token endpoints)
        if (endpoint.contains('oauth2/token') || endpoint.contains('/token')) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"mockAccessToken"}');
            return res;
        }

        // 2. Mock the initial Conga request (POST) - Checking the Sentinel Query IDs
        if (endpoint.contains('/v2/ingestion/merge') && req.getMethod() == 'POST') {
            
            // Scenario A: Case Field is Null Failure Test
            if (reqBody.contains('"queryId":"FAIL_NULL_CASE_SENTINEL"')) {
                res.setStatusCode(400); // Simulate a Bad Request failure
                res.setBody('{"error":"Simulated Case Null Error via Sentinel Query ID"}');
                return res;
            }
            
            // Scenario B: Generic Conga API Failure Test
            if (reqBody.contains('"queryId":"FAIL_GENERIC_API_SENTINEL"')) {
                res.setStatusCode(500); // Simulate an Internal Server Error
                res.setBody('{"error":"Simulated Generic Conga Failure via Sentinel Query ID"}');
                return res;
            }
            
            // Scenario C: Success Test Case (testFirstQueueableExecutionAndPollingSuccess)
            if (reqBody.contains('"queryId":"SR-Retail_SUCCESS_SENTINEL"')) {
                // Explicitly return success for the success test case
                res.setStatusCode(200);
                res.setBody('{"correlationId":"40955dd8240a45eca75a6ad660b72ea2_DatasetJson","status":"Accepted","result":{"statusCode":"Success"}}');
                return res;
            }

            // Default Fallback Success Response (If none of the above specific cases match)
            res.setStatusCode(200);
            res.setBody('{"correlationId":"40955dd8240a45eca75a6ad660b72ea2_DatasetJson","status":"Accepted","result":{"statusCode":"Success"}}');
            return res;
        }
        
        // 3. Mock the status check (GET)
        else if (endpoint.contains('/v2/jobs/status') && req.getMethod() == 'GET') {
            if (endpoint.contains('errorCorrelationId')) {
                res.setStatusCode(200);
                res.setBody('{"correlationId":"errorCorrelationId","message":"Error"}'); // Simulate Error Status
            } else {
                res.setStatusCode(200);
                res.setBody('{"correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","message":"Completed"}'); // Simulate Completed Status
            }
            return res;
        }
        
        // 4. Mock the document download (Optional but good practice)
        else if (endpoint.contains('/v2/jobs/download') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBodyAsBlob(Blob.valueOf('this is a test pdf document'));
            return res;
        }
        
        // Default response for un-mocked callouts
        else {
            res.setStatusCode(404);
            res.setBody('Mock HTTP Callout not found for endpoint: ' + endpoint);
            return res;
        }
    }
}