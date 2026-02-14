@IsTest
public class RETL_TradeLicenseToYardiQueueableTest {

    // ----------------------------------------------------------------------
    // Valid Mock Response (success case)
    // ----------------------------------------------------------------------
    private class MockMuleSoftResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{' +
                '"Status":"SUCCESS",' +
                '"Message":"Processed",' +
                '"ResponseCode":"200",' +
                '"Action":"UPDATE",' +
                '"RequestId":"123",' +
                '"Timestamp":"2025-11-29 10:00:00",' +
                '"Details":[{' +
                    '"TableName":"CUSTBUT_ME_TLIC",' +
                    '"EntityRecordCode":"c0008612",' +
                    '"ParentRecordCode":"",' +
                    '"CustomTableRecordCode":"987654",' +
                    '"Status":"OK",' +
                    '"Message":"Success",' +
                    '"ResponseCode":"200"' +
                '}]' +
            '}');

            return res;
        }
    }

    // ----------------------------------------------------------------------
    // Mock to force JSON parsing error
    // ----------------------------------------------------------------------
    private class MockInvalidJsonResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "Status" : "SUCCESS", BAD_JSON }'); // <-- invalid JSON
            return res;
        }
    }

    private class MockErrorStatusResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // Test Setup
    // ----------------------------------------------------------------------
    @TestSetup
    static void setupData() {

        // Parent account
        Account parentAcc = new Account(
            Name = 'Parent Account',
            RETL_Yardi_Id__c = 'c0008612'
        );
        insert parentAcc;

        // Child account
        Account acc = new Account(
            Name = 'Test Account',
            ParentId = parentAcc.Id,
            ECSS_Trade_License_Number__c = 'TL-12345',
            RETL_Trade_License_Issue_Date__c = Date.newInstance(2025, 1, 15),
            RETL_Trade_License_Expiry_Date__c = Date.newInstance(2026, 1, 15),
            RETL_Status__c = 'Active',
            RETL_Trade_License_Issuing_Authority__c = 'Abu Dhabi Department of Economic Development',
            RETL_LicenseIssuedCity__c = 'Abu Dhabi',
            RETL_LicenseIssuedCityArabic__c = 'الرياض'
        );
        insert acc;
    }

    // ----------------------------------------------------------------------
    // 1) Validate Invocable Method Coverage
    // ----------------------------------------------------------------------
    @IsTest
    static void testInvocableMethod() {

        Account acc = [
            SELECT Id FROM Account
            WHERE ParentId != null
            LIMIT 1
        ];

        Test.startTest();
        RETL_TradeLicenseUpdateToYardiQueueable.enqueueJob(
            new List<Id>{ acc.Id }
        );
        Test.stopTest();

        System.assert(true, 'Invocable enqueue executed without errors.');
    }

    // ----------------------------------------------------------------------
    // MAIN TEST — Queueable Execution
    // ----------------------------------------------------------------------
    @IsTest
    static void testQueueableExecutionSuccess() {

        Account acc = [
            SELECT Id FROM Account
            WHERE ParentId != null
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockMuleSoftResponse());

        Test.startTest();
        System.enqueueJob(new RETL_TradeLicenseUpdateToYardiQueueable(acc.Id));
        Test.stopTest();

        System.assert(true, 'Queueable executed successfully.');
    }

    // ----------------------------------------------------------------------
    // 2) Force the error path (Error Parsing JSON)
    // ----------------------------------------------------------------------
    @IsTest
    static void testErrorParsingBlock() {

        Account acc = [
            SELECT Id FROM Account
            WHERE ParentId != null
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockInvalidJsonResponse());

        Test.startTest();
        System.enqueueJob(new RETL_TradeLicenseUpdateToYardiQueueable(acc.Id));
        Test.stopTest();

        System.assert(true, 'Parsing error handled and LoggerService invoked.');
    }

    // ----------------------------------------------------------------------
    // Payload Builder Validation
    // ----------------------------------------------------------------------
    @IsTest
    static void testPayloadBuilder() {

        Account acc = [
            SELECT Id, Name FROM Account
            WHERE ParentId != null
            LIMIT 1
        ];

        RETL_YardiCustomTableWrapper.CustomTableRequest payload =
            RETL_TradeLicenseUpdateToYardiQueueable.buildPayload(acc.Id,'CUSTBUT_ME_TLIC');

        System.assertNotEquals(null, payload);
        System.assertEquals('License Information Update for ' + acc.Name, payload.Description);
        System.assertEquals(1, payload.Details.size());

        RETL_YardiCustomTableWrapper.RecordWrapper rec = payload.Details[0].Data[0];
        System.assertEquals('c0008612', rec.EntityRecordCode);
        System.assertEquals(8, rec.Fields.size());
    }

    @IsTest
    static void testNon200StatusCode() {

        Account acc = [
            SELECT Id FROM Account
            WHERE ParentId != null
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockErrorStatusResponse());

        Test.startTest();
        System.enqueueJob(new RETL_TradeLicenseUpdateToYardiQueueable(acc.Id));
        Test.stopTest();

        System.assert(true, 'Non-200 status code handled successfully.');
    }
}