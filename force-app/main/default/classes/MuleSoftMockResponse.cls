@isTest
global class MuleSoftMockResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(201);
        res.setBody(
            '{' +
                '"results": {' +
                    '"riskScore": 85,' +
                    '"riskLevel": "High",' +
                    '"riskUpdateDateTime": "2025-07-28T10:00:00Z",' +
                    '"riskErrorReason": "None"' +
                '}' +
            '}'
        );
        return res;
    }
}