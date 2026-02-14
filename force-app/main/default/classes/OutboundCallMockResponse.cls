@isTest
global class OutboundCallMockResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
       
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getEndpoint().contains('grant_type')){
            res.setBody('{"access_token":"123"}');
        }else if(req.getEndpoint().contains('contactlists') && req.getEndpoint().contains('contacts')){
            res.setBody('{"access_token":"123"}');
        }else if(req.getEndpoint().contains('contactlists')){
            res.setBody('{"entities":[{"id":"123","name":"'+Constants.CONTACTLIST_PAYMENT_REMINDER +'"}]}');
        }
        res.setStatusCode(200);
        return res;
    }
}