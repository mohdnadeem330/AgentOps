@IsTest
private class RETL_DocumentPDFprocessor_Test {
    
    // Constant for the expected file name from the Case field
    private static final String FILE_NAME_VALUE = 'Service_Request_Contract_PDF';
    
    @TestSetup
    static void setupTestData() {
        Account customerAcc = new Account(Name = 'Customer Account', Type = 'Customer');
        insert customerAcc;
        
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@test.com');
        insert con;
        
        // Case record with the required field for file naming logic
        Case testCase = new Case(
            Subject = 'Test Case', 
            Status = 'Active', 
            ContactId = con.Id, 
            AccountId = customerAcc.Id,
            RETL_SR_Service_Type__c = FILE_NAME_VALUE
        );
        insert testCase;
        
        APXTConga4__Conga_Template__c temp = new APXTConga4__Conga_Template__c();
        temp.APXTConga4__Name__c = 'SR-Retail';
        temp.APXTConga4__Template_Type__c = 'Document';
        insert temp;
        
        // 1. Success Document (Standard DocumentType)
        Document__c doc = new Document__c(Case__c = testCase.Id, DocumentType__c = 'SR-Retail_SUCCESS');
        insert doc;
        
        // 2. Document for Case Null Failure Test
        // DocumentType__c is the Sentinel base: FAIL_NULL_CASE
        Document__c failDoc1 = new Document__c(Case__c = null, DocumentType__c = 'FAIL_NULL_CASE');
        insert failDoc1;

        // 3. Document for Generic Failure Test
        // DocumentType__c is the Sentinel base: FAIL_GENERIC_API
        Document__c failDoc2 = new Document__c(Case__c = testCase.Id, DocumentType__c = 'FAIL_GENERIC_API');
        insert failDoc2;
    }

    @IsTest
    static void testInvokeUpdateAndGenerateSuccess() {
        Document__c doc = [SELECT Id,Case__c FROM Document__c WHERE DocumentType__c = 'SR-Retail_SUCCESS' LIMIT 1];
        APXTConga4__Conga_Template__c temp = [SELECT Id FROM APXTConga4__Conga_Template__c LIMIT 1];
        String templateId = temp.Id;
        String templateName = 'SR-Retail';

        RETL_DocumentPDFprocessor.FlowInput input = new RETL_DocumentPDFprocessor.FlowInput();
        input.documentId = doc.Id;
        input.templateId = templateId;
        input.templateName = templateName;
        
        List<RETL_DocumentPDFprocessor.FlowInput> inputs = new List<RETL_DocumentPDFprocessor.FlowInput>{input};
        
        Test.startTest();
        RETL_DocumentPDFprocessor.invokeUpdateAndGenerate(inputs);
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Conga_template__c, DocumentType__c FROM Document__c WHERE Id = :doc.Id];
        System.assertEquals(templateId, updatedDoc.Conga_template__c, 'Conga template ID should be updated.');
    }

    /*@IsTest
    static void testFirstQueueableExecutionAndPollingSuccess() {
        Document__c doc = [SELECT Id, Case__c FROM Document__c WHERE DocumentType__c = 'SR-Retail_SUCCESS' LIMIT 1];
        APXTConga4__Conga_Template__c temp = [SELECT Id FROM APXTConga4__Conga_Template__c LIMIT 1];
        String templateId = temp.Id;
        String expectedFileName = FILE_NAME_VALUE; 

        Test.setMock(HttpCalloutMock.class, new CongaMockHttpResponseGenerator());
        
        // Simulate File Attachment (required for externalFileLinkCreation logic)
        ContentVersion cv = new ContentVersion();
        cv.Title = expectedFileName; 
        cv.PathOnClient = expectedFileName.replaceAll('[^a-zA-Z0-9_\\-]', '_') + '.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        insert cv;
        
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = doc.Id; 
        cdl.ShareType = 'V'; 
        insert cdl;

        Test.startTest();
        System.enqueueJob(new RETL_DocumentPDFprocessor(doc.Id, templateId, expectedFileName));
        System.enqueueJob(new RETL_DocumentPDFprocessor(doc.Id, templateId, expectedFileName, '40955dd8240a45eca75a6ad660b72ea2_DatasetJson')); 
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Correlation_ID__c FROM Document__c WHERE Id = :doc.Id];
        System.assertNotEquals(null, updatedDoc.Correlation_ID__c, 'Correlation ID should be set after the first job execution.');

        // Assert File Naming and Attachment
        List<ContentVersion> createdVersions = [SELECT Id FROM ContentVersion WHERE Title = :expectedFileName];
        System.assertEquals(1, createdVersions.size(), 'ContentVersion should exist with the expected Case field value as Title.');
    }*/

    @IsTest
    static void testQueueableAbortsGracefully() {
        Document__c doc = [SELECT Id FROM Document__c WHERE DocumentType__c = 'SR-Retail_SUCCESS' LIMIT 1];
        APXTConga4__Conga_Template__c temp = [SELECT Id FROM APXTConga4__Conga_Template__c LIMIT 1];
        String templateId = temp.Id;
        String templateName = 'SR-Retail';
        
        doc.Correlation_ID__c = 'NewCorrelationId';
        update doc;

        RETL_DocumentPDFprocessor oldJob = new RETL_DocumentPDFprocessor(doc.Id, templateId, templateName, 'OldCorrelationId');
        
        Test.startTest();
        System.enqueueJob(oldJob);
        Test.stopTest();
        
        System.assertEquals(0, Limits.getQueueableJobs(), 'No new jobs should be enqueued when an old job is aborted.');
    }

    @IsTest
    static void testCongaRequestCaseFieldIsNull() {
        // Find the document created for this failure scenario
        Document__c doc = [SELECT Id, DocumentType__c FROM Document__c WHERE DocumentType__c = 'FAIL_NULL_CASE' LIMIT 1];
        APXTConga4__Conga_Template__c temp = [SELECT Id FROM APXTConga4__Conga_Template__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CongaMockHttpResponseGenerator());

        Test.startTest();
        // The mock will look for 'FAIL_NULL_CASE_SENTINEL' in queryId
        System.enqueueJob(new RETL_DocumentPDFprocessor(doc.Id, temp.Id, 'Dummy Name'));
        Test.stopTest();

        Document__c updatedDoc = [SELECT Correlation_ID__c FROM Document__c WHERE Id = :doc.Id];
        // Assertion: Expected: null
        System.assertEquals(null, updatedDoc.Correlation_ID__c, 'Correlation ID should remain null if the Case field check failed (simulated).');
    }

    @IsTest
    static void testCongaRequestFailure() {
        // Find the document created for this failure scenario
        Document__c doc = [SELECT Id, DocumentType__c FROM Document__c WHERE DocumentType__c = 'FAIL_GENERIC_API' LIMIT 1];
        APXTConga4__Conga_Template__c temp = [SELECT Id FROM APXTConga4__Conga_Template__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CongaMockHttpResponseGenerator());

        Test.startTest();
        // The mock will look for 'FAIL_GENERIC_API_SENTINEL' in queryId
        System.enqueueJob(new RETL_DocumentPDFprocessor(doc.Id, temp.Id, 'Dummy Name'));
        Test.stopTest();

        Document__c updatedDoc = [SELECT Correlation_ID__c FROM Document__c WHERE Id = :doc.Id];
        // Assertion: Expected: null
        System.assertEquals(null, updatedDoc.Correlation_ID__c, 'Correlation ID should be null if the initial Conga request failed (simulated).');
    }

    @IsTest
    static void testPollingStatusError() {
        Document__c doc = [SELECT Id FROM Document__c WHERE DocumentType__c = 'SR-Retail_SUCCESS' LIMIT 1];
        doc.Correlation_ID__c = 'errorCorrelationId';
        update doc;
        
        Test.setMock(HttpCalloutMock.class, new CongaMockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new RETL_DocumentPDFprocessor(doc.Id, 'tempId3', 'tempName3', doc.Correlation_ID__c));
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(), 'No new jobs should be enqueued when Conga returns "Error" status.');
    }
}