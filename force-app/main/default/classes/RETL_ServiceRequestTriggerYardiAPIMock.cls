@IsTest
public class RETL_ServiceRequestTriggerYardiAPIMock implements HttpCalloutMock {
    boolean isError;
    public RETL_ServiceRequestTriggerYardiAPIMock(boolean isError) { this.isError = isError; }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if (isError) {
            res.setStatusCode(500);
            res.setBody('{"Status":"Failure", "ResponseCode":"500"}');
        } else {
            res.setStatusCode(200);
            // This Body matches your required structure to cover the "Details" loop
            String body = '{' +
                '"ResponseCode": "200",' +
                '"Details": [' +
                    '{' +
                        '"EntityRecordCode": "859",' +
                        '"ResponseCode": "201",' +
                        '"Status": "Success",' +
                        '"Message": "Custom Table Update Successful.",' +
                        '"TableName": "AMENDBUT_FITOUT_MILESTONES_TMP"' +
                    '},' +
                    '{' +
                        '"EntityRecordCode": "4000",' +
                        '"ResponseCode": "404",' +
                        '"Status": "Failure",' +
                        '"Message": "Record already exist.",' +
                        '"TableName": "AMENDBUT_FITOUT_MILESTONES_TMP"' +
                    '}' +
                ']' +
            '}';
            res.setBody(body);
        }
        return res;
    }
}