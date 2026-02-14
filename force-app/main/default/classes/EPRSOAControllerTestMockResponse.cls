global class EPRSOAControllerTestMockResponse implements HttpCalloutMock{
    
     // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"results":{"id":"123","soaFile":"VGVzdCBJIGhhdmU="}}');
        res.setStatusCode(200);
        return res;
    }

}