@isTest
global class SMSMockResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[{"ErrorCode":0,"Description":"Success","Id":"93e626eb-d3c9-42f5-b0df-15dbd18f64d7","OriginatingAddress":"SenderID","DestinationAddress":"97150XXXXXX","MessageCount":1},{"ErrorCode":0,"Description":"Success","Id":"7d2b28fb-abb2-4a77-88a2-f0fa83baa03d","OriginatingAddress":"SenderID","DestinationAddress":"97155XXXXXX","MessageCount":1} ]');
        res.setStatusCode(200);
        return res;
    }
}