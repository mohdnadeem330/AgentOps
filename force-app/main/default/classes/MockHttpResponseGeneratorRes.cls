@isTest
global class MockHttpResponseGeneratorRes implements HttpCalloutMock {
    global String body;
    global MockHttpResponseGeneratorRes(String body){
        this.body = body;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
         
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(200);
        return res;
    }
}