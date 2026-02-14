@isTest
global class DLPMockResponse implements HttpCalloutMock {
    global String body;
    global Integer statusCode;

    global DLPMockResponse(String body, Integer statusCode){
        this.body = body;
        this.statusCode = statusCode;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
         
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);

        return res;
    }
}