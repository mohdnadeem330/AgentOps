@IsTest
private class RETL_WorkOrderForDealUpdateQueueableTest {

    /*
     =========================================================================
        MOCK CALLOUT
     =========================================================================
    */
    private class MockWorkOrderCallout implements HttpCalloutMock {

        Integer statusCode;
        String responseBody;
        Boolean isError;

        public MockWorkOrderCallout(Integer code, String body, Boolean err) {
            statusCode = code;
            responseBody = body;
            isError = err;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setStatus(isError ? 'ERROR' : 'OK');
            res.setBody(responseBody);
            return res;
        }
    }


    /*
     =========================================================================
        TEST DATA
     =========================================================================
    */
    @TestSetup
    static void setupData() {

        // Project (Parent for Opportunity)
        Project__c prj = new Project__c(
            Name = 'Test Project',
            RETL_Property_Yardi_Code__c = 'PROP001',
            BusinessUnitId__c = 'Al Dar',
            ProjectCode__c = 'PRJ001'           
        );
        insert prj;

        // Opportunity with required fields
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            RETL_Tenant_Code__c = 'TEN001',
            RETL_Project__c = prj.Id
        );
        insert opp;

        
    }


    /*
     =========================================================================
        SUCCESS SCENARIO
     =========================================================================
    */
    @IsTest
    static void testSuccessScenario() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Valid MuleSoft response
        Test.setMock(
            HttpCalloutMock.class,
            new MockWorkOrderCallout(
                200,
                '{"Yardi_WO_Code":"WO12345"}',
                false
            )
        );

        Test.startTest();
        System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(opp.Id));
        Test.stopTest();

        // Validate Opportunity is updated
        Opportunity updated =
            [SELECT RETL_WO_Yardi_Id__c FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(
            'WO12345',
            updated.RETL_WO_Yardi_Id__c,
            'Should update Opportunity with Yardi WO Code'
        );
    }


    /*
     =========================================================================
        NULL RESPONSE TEST
     =========================================================================
    */
    @IsTest
    static void testNullResponse() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockWorkOrderCallout(200, null, false)
        );

        Test.startTest();
        System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(opp.Id));
        Test.stopTest();

        // Should not update WO Code
        Opportunity updated = [
            SELECT RETL_WO_Yardi_Id__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(
            null,
            updated.RETL_WO_Yardi_Id__c,
            'No update expected on NULL response'
        );
    }


    /*
     =========================================================================
        FAILURE RESPONSE (HTTP 500)
     =========================================================================
    */
    @IsTest
    static void testServerError() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockWorkOrderCallout(
                500,
                '{"error":"Internal error"}',
                true
            )
        );

        Test.startTest();
        System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(opp.Id));
        Test.stopTest();

        // Should NOT update Opportunity
        Opportunity updated = [
            SELECT RETL_WO_Yardi_Id__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(
            null,
            updated.RETL_WO_Yardi_Id__c,
            'WO Code must not update on failure'
        );
    }
    
    
}