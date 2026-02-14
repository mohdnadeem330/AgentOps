@isTest
global class QualtricsMockResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Status":"CXM200-1","Message":"Success - Queue Initiated","QueueId":"2beeea60-0cc2-11ed-8e83-2583172bb54c"}');
        res.setStatusCode(200);
        return res;
    }
}