@isTest
public class CAFMCalloutToMuleSoftTest {
    @isTest
    static void testWrapper() {
        String jsonInput = '{' +
            '"applicationName": "x-ald-sferp-api",' +
            '"success": true,' +
            '"statusCode": "200",' +
            '"correlationId": "c9c1be70-70d4-11ef-8d9c-0249d7a827d7",' +
            '"results": {' +
            '"CreateBreakdownTaskResponse": {' +
            '"CreateBreakdownTaskResult": {' +
            '"PrimaryKeyId": "7931640",' +
            '"TaskId": "TASK123",' +
            '"Code": "CODE123",' +
            '"TaskPerfSLAAttendDate": "2024-10-30T10:15:30Z",' +
            '"TaskPerfSLAFixDate": "2024-11-01T11:45:00Z"' +
            '}' +
            '}' +
            '}' +
            '}';
        // Deserialize JSON into MuleResCAFMWrapper instance
        CAFM_MuleResWrapper.parse(jsonInput);
    }
    @isTest
    static void testCAFMCaseCreationBatch() {
       // try{
            Id cafmRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_CAFM').getRecordTypeId();
            Case  testCases =new Case(
                RecordTypeId = cafmRecordTypeId,
                Subject = 'Test CAFM Case ' ,
                Status = 'New',
                Priority = 'P1',
                SuppliedName = 'Test User',
                Type = 'Breakdown',               
                SuppliedEmail = 'testuser@example.com',              
                SuppliedPhone = '123-456-7890');


            String jsonInput = '{' +
                '"applicationName": "x-ald-sferp-api",' +
                '"success": true,' +
                '"statusCode": "200",' +
                '"correlationId": "c9c1be70-70d4-11ef-8d9c-0249d7a827d7",' +
                '"results": {' +
                '"CreateBreakdownTaskResponse": {' +
                '"CreateBreakdownTaskResult": {' +
                '"PrimaryKeyId": "7931640",' +
                '"TaskId": "TASK123",' +
                '"Code": "CODE123",' +
                '"TaskPerfSLAAttendDate": "2024-10-30T10:15:30Z",' +
                '"TaskPerfSLAFixDate": "2024-11-01T11:45:00Z"' +
                '}' +
                '}' +
                '}' +
                '}';         

            // Step 2: Set up the mock for HTTP callout
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // Step 3: Run the batch with the test data
            Test.startTest();
            insert testCases;
            CAFMCalloutToMuleSoft.callCAFMCaseCreationQueue(new list<id>{testCases.id});
            Test.stopTest();
        //}catch(exception e){}
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":{"CreateBreakdownTaskResponse":{"CreateBreakdownTaskResult":{"TaskId":"1234599","Code":"TASK123","TaskPerfSLAAttendDate":"2024-09-27T08:00:00.000","TaskPerfSLAFixDate":"2024-09-27T08:00:00.000"}}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testCAFMCaseCreationBatchWithError() {
        // Test the error path by simulating a failed HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator());
        Id cafmRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_CAFM').getRecordTypeId();
        Case  testCases =new Case(
            RecordTypeId = cafmRecordTypeId,
            Subject = 'Test CAFM Case ' ,
            Status = 'New',
            Priority = 'P1',
            SuppliedName = 'Test User',
            Type = 'Breakdown',               
            SuppliedEmail = 'testuser@example.com',              
            SuppliedPhone = '123-456-7890');        

        Test.startTest();
       // try{
            insert testCases;
        //}catch(exception e){}      
        CAFMCalloutToMuleSoft.callCAFMCaseCreationQueue(new list<id>{testCases.id});
        Test.stopTest();
    }
    // Mock HTTP error response generator class
    private class MockHttpErrorResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Bad Request"}');
            res.setStatusCode(400);
            return res;
        }
    }

}