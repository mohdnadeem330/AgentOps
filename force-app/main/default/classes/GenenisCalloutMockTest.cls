@isTest
global class GenenisCalloutMockTest implements HttpCalloutMock {
    global String body;
    global Integer statusCode;

    global GenenisCalloutMockTest(String body, Integer statusCode){
        this.body = body;
        this.statusCode = statusCode;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
         
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);

        return res;
    }
}