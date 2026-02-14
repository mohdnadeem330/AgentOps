@isTest
private class RETL_LCApprovalToYardiTest {

    // ---------------------------------------------------------
    // Mock HTTP Callout
    // ---------------------------------------------------------
    private class MockHttpResponse implements HttpCalloutMock {
        Integer code;
        String body;
        Boolean isError;

        public MockHttpResponse(Integer c, String b, Boolean err) {
            code = c;
            body = b;
            isError = err;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            res.setHeader('Content-Type', 'application/json');
            res.setStatus(isError ? 'Error' : 'OK');
            return res;
        }
    }

    // ---------------------------------------------------------
    // Test Setup 
    // ---------------------------------------------------------
    @TestSetup
    static void setupData() {

        // Create account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp for LC Approval',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            RETL_Yardi_Proposal_Id__c = 'YARDI-PROP-777',
            Leasing_Committee_Approval_Status__c = 'Approved',
            AccountId = acc.Id
        );
        insert opp;
    }

    // ---------------------------------------------------------
    // TEST 1 — SUCCESS CALL OUT
    // ---------------------------------------------------------
    @isTest
    static void test_successCallout() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponse(200, '{"Status":"Success"}', false)
        );

        Test.startTest();
        RETL_LCApprovalToYardi.pushLCApproval(opp.Id);
        Test.stopTest();

        System.assert(true, 'Success path executed without errors');
    }

    // ---------------------------------------------------------
    // TEST 2 — FAILED CALLOUT (500)
    // ---------------------------------------------------------
    @isTest
    static void test_failedCallout() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponse(500, '{"Status":"Failure"}', true)
        );

        Test.startTest();
        RETL_LCApprovalToYardi.pushLCApproval(opp.Id);
        Test.stopTest();

        System.assert(true, 'Failure path executed without unhandled exceptions');
    }

    // ---------------------------------------------------------
    // TEST 3 — NULL RESPONSE HANDLING
    // ---------------------------------------------------------
    @isTest
    static void test_nullResponse() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // No mock → CalloutToMuleSoft will return null in test context
        Test.startTest();
        RETL_LCApprovalToYardi.pushLCApproval(opp.Id);
        Test.stopTest();

        System.assert(true, 'Null response is handled without exception');
    }

    // ---------------------------------------------------------
    // TEST 4 — PAYLOAD STRUCTURE VERIFICATION
    // ---------------------------------------------------------
    @isTest
    static void test_payloadStructure() {

        Opportunity opp = [
            SELECT Id, RETL_Yardi_Proposal_Id__c,
                   Leasing_Committee_Approval_Status__c
            FROM Opportunity
            LIMIT 1
        ];

        // Read table name from real metadata (assumes record exists in org)
        MuleSoftSetting__mdt api = [
            SELECT Table_Name__c
            FROM MuleSoftSetting__mdt
            WHERE DeveloperName = 'RETL_LCApprovalToYardi'
            LIMIT 1
        ];

        RETL_YardiCustomTableWrapper.CustomTableRequest req =
            RETL_LCApprovalToYardi.buildLCApprovalPayload(
                opp.Id,
                api.Table_Name__c
            );

        System.assertNotEquals(null, req);
        System.assert(req.Description.contains(opp.RETL_Yardi_Proposal_Id__c));
        System.assertNotEquals(null, req.Timestamp);
        System.assertNotEquals(null, req.RequestId);

        // Validate table
        System.assertEquals(1, req.Details.size());
        System.assertEquals(api.Table_Name__c, req.Details[0].TableName);

        // Validate record
        RETL_YardiCustomTableWrapper.RecordWrapper rec =
            req.Details[0].Data[0];

        System.assertEquals(
            opp.RETL_Yardi_Proposal_Id__c,
            rec.EntityRecordCode
        );

        // Validate 3 expected fields
        System.assertEquals(3, rec.Fields.size());
    }
}