@isTest
private class RETL_CancelProposalInYardiTest {

     // -------------------------
    // Mock Callout Class
    // -------------------------
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean isError;

        public MockHttpResponseGenerator() {
            this.statusCode = 200;
            this.responseBody = '{"Status":"Success", "Message":"Proposal cancelled in Yardi."}';
            this.isError = false;
        }

        public MockHttpResponseGenerator(Integer status, String body, Boolean error) {
            this.statusCode = status;
            this.responseBody = body;
            this.isError = error;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            res.setStatus(isError ? 'Error' : 'OK');
            return res;
        }
    }

    // -------------------------
    // Test Setup
    // -------------------------
    @TestSetup
    static void setupTestData() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Cancel Proposal Opp',
            StageName = 'Proposal',
            CloseDate = Date.today().addMonths(1),
            RETL_Yardi_Proposal_Id__c = 'YARDI-PROP-12345'
        );
        insert testOpp;
    }

    // -------------------------
    // Tests
    // -------------------------
    @IsTest
    static void pushCancelProposal_SuccessTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String cancelReason = 'Customer changed mind';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            '{"Status":"Success", "Message":"Proposal cancelled."}', 
            false
        ));

        Test.startTest();
        RETL_CancelProposalInYardi.pushCancelProposal(opp.Id, cancelReason);
        Test.stopTest();

        System.assert(true, 'pushCancelProposal should complete without exceptions.');
    }

    @IsTest
    static void pushCancelProposal_MissingMuleSoftConfigTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        RETL_CancelProposalInYardi.pushCancelProposal(opp.Id, 'Test');
        Test.stopTest();
    }

    @IsTest
    static void pushCancelProposal_CalloutFailureTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            500, 
            '{"Status":"Failure", "Error":"Yardi Timeout"}',
            true
        ));

        Test.startTest();
        RETL_CancelProposalInYardi.pushCancelProposal(opp.Id, 'Test Callout Failure');
        Test.stopTest();
    }

    @IsTest
    static void pushCancelProposal_NullResponseTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        RETL_CancelProposalInYardi.pushCancelProposal(opp.Id, 'Test Null Response');
        Test.stopTest();
    }

      @IsTest
    static void buildCancelProposalPayload_StructureTest() {

        Opportunity opp = [
            SELECT Id, RETL_Yardi_Proposal_Id__c 
            FROM Opportunity LIMIT 1
        ];

        RETL_YardiCustomTableWrapper.CustomTableRequest result =
            RETL_CancelProposalInYardi.buildCancelProposalPayload(
                opp.Id, 'QA check', 'AMENDBUT_PROPOSAL_STATUS'
            );

        // -------------------------
        // Root Request Assertions
        // -------------------------
        System.assert(result != null, 'Payload should not be null.');
        System.assert(result.Description.contains('Cancel Proposal'), 'Description is incorrect.');
        System.assertNotEquals(null, result.RequestId, 'RequestId should not be null.');
        System.assertEquals(1, result.Details.size(), 'Details list should have 1 table.');

        // -------------------------
        // Table Assertions
        // -------------------------
        RETL_YardiCustomTableWrapper.TableWrapper table = result.Details[0];
        System.assertEquals('AMENDBUT_PROPOSAL_STATUS', table.TableName, 'TableName mismatch.');
        System.assertEquals(1, table.Data.size(), 'Table Data list should have 1 record.');

        // -------------------------
        // Record Assertions
        // -------------------------
        RETL_YardiCustomTableWrapper.RecordWrapper rec = table.Data[0];
        System.assertEquals(opp.RETL_Yardi_Proposal_Id__c, rec.EntityRecordCode, 'EntityRecordCode mismatch.');
        System.assertEquals(2, rec.Fields.size(), 'Fields list should have 2 items.');

        // -------------------------
        // Field Assertions
        // -------------------------
        RETL_YardiCustomTableWrapper.FieldWrapper field1 = rec.Fields[0];
        RETL_YardiCustomTableWrapper.FieldWrapper field2 = rec.Fields[1];

        System.assertEquals('hCancelProposal', field1.FieldName);
        System.assertEquals('YES', field1.FieldValue);

        System.assertEquals('Reason', field2.FieldName);
        System.assertEquals('QA check', field2.FieldValue);
    }
}