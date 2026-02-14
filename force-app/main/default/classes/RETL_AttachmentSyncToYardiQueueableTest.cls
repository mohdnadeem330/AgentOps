@IsTest
public class RETL_AttachmentSyncToYardiQueueableTest {

    // Helper to create and link test records
    private static Map<String, Id> createTestRecords() {
        Map<String, Id> ids = new Map<String, Id>();

        // 1. Create a test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            RETL_Yardi_Id__c = 'YARDI123'
        );
        insert testOpp;
        ids.put('opportunityId', testOpp.Id);

        // 2. Create a test content version (file)
        ContentVersion testFile = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test data for the file'),
            ContentLocation = 'S'
        );
        insert testFile;

        // 3. Retrieve ContentDocument Id
        testFile = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testFile.Id];
        ids.put('contentDocumentId', testFile.ContentDocumentId);
        ids.put('contentVersionId', testFile.Id); 

        // 4. Link the ContentDocument to the Opportunity using ContentDocumentLink
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = testFile.ContentDocumentId;
        link.LinkedEntityId = testOpp.Id; // Link to the Opportunity
        link.ShareType = 'V'; 
        link.Visibility = 'AllUsers';
        insert link;

        return ids;
    }

    
    @IsTest
    static void test_ValidAttachmentSyncWithMuleSoft() {
        // Create data specific to this test method
        Map<String, Id> testIds = createTestRecords();
        Id opportunityId = testIds.get('opportunityId');
        Id contentVersionId = testIds.get('contentVersionId');
        Id contentDocumentId = testIds.get('contentDocumentId');

        Test.startTest();

        // Mock the callout response to simulate a successful response from MuleSoft
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201, '{"Status": "Success", "Yardi_Attachment_id": "YARDI456", "SF_Ref_Attachment_Id": "001"}'));

        // Enqueue the job
        RETL_AttachmentSyncToYardiQueueable.enqueueJob(opportunityId, contentVersionId);

        Test.stopTest(); // This will trigger the queued job

        // Query for the latest ContentVersion using ContentDocumentId
        ContentVersion updatedContentVersion = [
            SELECT RETL_Yardi_Id__c 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        // Assert that the Yardi ID was set correctly after a successful callout
        System.assertEquals('YARDI456', updatedContentVersion.RETL_Yardi_Id__c, 'ContentVersion should have the Yardi Attachment ID after the successful callout.');
    }

    @IsTest
    static void test_FailedAttachmentSyncWithMuleSoft() {
        // Create data specific to this test method
        Map<String, Id> testIds = createTestRecords();
        Id opportunityId = testIds.get('opportunityId');
        Id contentVersionId = testIds.get('contentVersionId');
        Id contentDocumentId = testIds.get('contentDocumentId');

        Test.startTest();

        // Mock the callout response to simulate a failed response from MuleSoft (400 Bad Request)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, 'Bad Request'));

        // Enqueue the job
        RETL_AttachmentSyncToYardiQueueable.enqueueJob(opportunityId, contentVersionId);

        Test.stopTest(); // This will trigger the queued job

        // Query for the latest ContentVersion using ContentDocumentId
        ContentVersion updatedContentVersion = [
            SELECT RETL_Yardi_Id__c 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        // Assert that the Yardi ID was not set due to the failed callout
        System.assertEquals(null, updatedContentVersion.RETL_Yardi_Id__c, 'ContentVersion should not have a Yardi Attachment ID after a failed callout.');
    }


    /* @IsTest
    static void test_FailedAttachmentSyncWithMuleSoftError() {
        // Assuming you use the createTestRecords helper method from the previous fix
        Map<String, Id> testIds = createTestRecords();
        Id opportunityId = testIds.get('opportunityId');
        Id contentVersionId = testIds.get('contentVersionId');
        Id contentDocumentId = testIds.get('contentDocumentId');

        Test.startTest();

        // Mock the callout response to simulate a failed response (400 Bad Request)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"Status": "Failed", "Error_Message": "Invalid input data."}'));

        // Enqueue the job
        RETL_AttachmentSyncToYardiQueueable.enqueueJob(opportunityId, contentVersionId);

        Test.stopTest(); // This will trigger the queued job

        // Query for the latest ContentVersion
        ContentVersion updatedContentVersion = [
            SELECT RETL_Yardi_Id__c 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        // Assert that the Yardi ID was not set due to the failed callout
        System.assertEquals(null, updatedContentVersion.RETL_Yardi_Id__c, 'ContentVersion should not have a Yardi Attachment ID after a failed callout.');
    } */


    /* @IsTest
    static void test_AttachmentSyncWithMuleSoft_AppStatusError() {
        // Create data specific to this test method
        Map<String, Id> testIds = createTestRecords();
        Id opportunityId = testIds.get('opportunityId');
        Id contentVersionId = testIds.get('contentVersionId');
        Id contentDocumentId = testIds.get('contentDocumentId');

        Test.startTest();

        // 2. Mock the callout response with a successful HTTP status (200/201), 
        //    but with an application Status of 'Error'.
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"Status": "Error", "ErrorMessage": "Yardi rejected the file type."}'));

        // Enqueue the job
        RETL_AttachmentSyncToYardiQueueable.enqueueJob(opportunityId, contentVersionId);

        Test.stopTest();

        

        // Re-check ContentVersion to ensure no update happened
        ContentVersion updatedContentVersion = [
            SELECT RETL_Yardi_Id__c 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals(null, updatedContentVersion.RETL_Yardi_Id__c, 'Yardi ID must be null after application error.');
    } */

    // Mocking HTTP Callout Response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}