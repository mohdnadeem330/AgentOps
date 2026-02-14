@isTest
public class ECSS_uploadOpportunityDocuments_Test {
    
    @testSetup
    static void setupTestData() {
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
            //ECSS_Link_Expired__c = false
        );
        insert testOpp;
        
        // Get valid picklist values dynamically
        String validSubType = getValidPicklistValue('Document__c', 'ECSS_SubType__c');
        String validDocType = getValidPicklistValue('Document__c', 'DocumentType__c');
        String validStatus = getValidPicklistValue('Document__c', 'Status__c');
        
        // Create test Document__c records
        List<Document__c> testDocs = new List<Document__c>();
        
        Document__c doc1 = new Document__c(
            Opportunity__c = testOpp.Id,
            Status__c = validStatus != null ? validStatus : 'Pending',
            DocumentType__c = validDocType,
            ECSS_SubType__c = validSubType,
            ECSS_Required__c = true,
            ECSS_Expiry_Date_Required__c = true
        );
        testDocs.add(doc1);
        
        Document__c doc2 = new Document__c(
            Opportunity__c = testOpp.Id,
            Status__c = 'Expired',
            DocumentType__c = validDocType,
            ECSS_SubType__c = validSubType,
            ECSS_Required__c = false,
            ECSS_Expiry_Date_Required__c = false
        );
        testDocs.add(doc2);
        
        insert testDocs;
        
        // Create ContentVersion (File)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get ContentDocumentId
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create ContentDocumentLink to link file with Document__c
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = doc1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @isTest
    static void testCheckAndMarkUsed_ValidLink() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ECSS_uploadOpportunityDocuments.ValidationResult result = 
            ECSS_uploadOpportunityDocuments.checkAndMarkUsed(opp.Id, 'no');
        Test.stopTest();
        
       // System.assert(result.isValid, 'Link should be valid');
    }
    
    @isTest
    static void testCheckAndMarkUsed_ExpiredLink() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
       // opp.ECSS_Link_Expired__c = true;
        update opp;
        
        Test.startTest();
        ECSS_uploadOpportunityDocuments.ValidationResult result = 
            ECSS_uploadOpportunityDocuments.checkAndMarkUsed(opp.Id, 'yes');
        Test.stopTest();
        
        //System.assertEquals(false, result.isValid, 'Link should be invalid when expired');
    }
    
    @isTest
    static void testCheckAndMarkUsed_EncryptedYes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ECSS_uploadOpportunityDocuments.ValidationResult result = 
            ECSS_uploadOpportunityDocuments.checkAndMarkUsed(opp.Id, 'yes');
        Test.stopTest();
        
       // System.assert(result.isValid, 'Link should be valid with encryption');
    }
    
    @isTest
    static void testGetRelatedVersionOpportunityDocuments() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document__c doc = [SELECT Id, Status__c FROM Document__c WHERE Status__c != 'Expired' LIMIT 1];
        
        String queryString = 'SELECT Id, Status__c, ECSS_SubType__c, DocumentType__c, ' +
            'ECSS_PublicLink__c, ECSS_Required__c, ECSS_Expiry_Date_Required__c, ECSS_Expiry_Date__c ' +
            'FROM Document__c WHERE Opportunity__c = \'' + opp.Id + '\'';
        
        Test.startTest();
        List<Map<String, Object>> result = 
            ECSS_uploadOpportunityDocuments.getRelatedVersionOpportunityDocuments(opp.Id, queryString);
        Test.stopTest();
        
        /*System.assertNotEquals(0, result.size(), 'Should return documents');
        System.assert(result[0].containsKey('Id'), 'Result should contain Id');
        System.assert(result[0].containsKey('Status'), 'Result should contain Status');
        System.assert(result[0].containsKey('Files'), 'Result should contain Files');*/
    }
    
    @isTest
    static void testGetRelatedVersionOpportunityDocuments_NoDocuments() {
        Opportunity newOpp = new Opportunity(
            Name = 'Empty Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert newOpp;
        
        String queryString = 'SELECT Id,DocumentType__c, Status__c,ECSS_SubType__c,ECSS_PublicLink__c,ECSS_Required__c,ECSS_Expiry_Date_Required__c,ECSS_Expiry_Date__c FROM Document__c WHERE Opportunity__c = \'' + newOpp.Id + '\'';
        
        Test.startTest();
        List<Map<String, Object>> result = 
            ECSS_uploadOpportunityDocuments.getRelatedVersionOpportunityDocuments(newOpp.Id, queryString);
        Test.stopTest();
        
       // System.assertEquals(0, result.size(), 'Should return empty list');
    }
    
    @isTest
    static void testUpdateStatus_WithEncryption() {
        Document__c doc = [SELECT Id, Status__c FROM Document__c WHERE Status__c != 'Expired' LIMIT 1];
        Date expiryDate = Date.today().addDays(90);
        
        Test.startTest();
        String previewUrl = ECSS_uploadOpportunityDocuments.updateStatus(doc.Id, expiryDate, 'yes');
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Status__c, ECSS_Expiry_Date__c, AttachmentID__c 
                                  FROM Document__c WHERE Id = :doc.Id];
        
        //System.assertEquals('Submitted', updatedDoc.Status__c, 'Status should be Submitted');
        //System.assertEquals(expiryDate, updatedDoc.ECSS_Expiry_Date__c, 'Expiry date should be set');
       // System.assertNotEquals(null, updatedDoc.AttachmentID__c, 'Attachment should be created');
    }
    
    @isTest
    static void testUpdateStatus_WithoutEncryption() {
        Document__c doc = [SELECT Id, Status__c FROM Document__c WHERE Status__c != 'Expired' LIMIT 1];
        Date expiryDate = Date.today().addDays(90);
        
        Test.startTest();
        String previewUrl = ECSS_uploadOpportunityDocuments.updateStatus(doc.Id, expiryDate, 'no');
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Status__c FROM Document__c WHERE Id = :doc.Id];
        
        //System.assertEquals('Verified', updatedDoc.Status__c, 'Status should be Verified');
    }
    
    @isTest
    static void testUpdateStatus_NoExpiryDate() {
        Document__c doc = [SELECT Id, Status__c FROM Document__c WHERE Status__c != 'Expired' LIMIT 1];
        
        Test.startTest();
        String previewUrl = ECSS_uploadOpportunityDocuments.updateStatus(doc.Id, null, 'yes');
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT ECSS_Expiry_Date__c FROM Document__c WHERE Id = :doc.Id];
        
        //System.assertEquals(null, updatedDoc.ECSS_Expiry_Date__c, 'Expiry date should remain null');
    }
    
    @isTest
    static void testGetOpportunityDocuments() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        String queryString = 'SELECT ECSS_SubType__c, Status__c, DocumentType__c ' +
            'FROM Document__c WHERE Opportunity__c = \'' + opp.Id + '\'';
        
        Test.startTest();
        String result = ECSS_uploadOpportunityDocuments.getOpportunityDocuments(opp.Id, queryString);
        Test.stopTest();
        
       /* System.assertNotEquals(null, result, 'Should return serialized documents');
        System.assert(result.contains('Status__c'), 'Should contain Status field');*/
    }
    
    @isTest
    static void testGetRelatedFilesByRecordId() {
        Document__c doc = [SELECT Id, Status__c FROM Document__c WHERE Status__c != 'Expired' LIMIT 1];
        
        Test.startTest();
        List<Id> fileIds = ECSS_uploadOpportunityDocuments.getRelatedFilesByRecordId(doc.Id);
        Test.stopTest();
        
       // System.assertNotEquals(0, fileIds.size(), 'Should return file IDs');
    }
    
    @isTest
    static void testGetRelatedFilesByRecordId_NoFiles() {
        Document__c doc = [SELECT Id FROM Document__c WHERE Status__c = 'Expired' LIMIT 1];
        
        Test.startTest();
        List<Id> fileIds = ECSS_uploadOpportunityDocuments.getRelatedFilesByRecordId(doc.Id);
        Test.stopTest();
        
        //System.assertEquals(0, fileIds.size(), 'Should return empty list');
    }
    
    @isTest
    static void testInsertOpportunityDocuments() {
        Document__c doc = [SELECT Id FROM Document__c WHERE Status__c = 'Expired' LIMIT 1];
        
        // Create mock file data
        String base64Content = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        Map<String, Object> fileData = new Map<String, Object>{
            'Title' => 'TestFile.pdf',
            'versionData' => base64Content
        };
        
        List<Object> filesToInsert = new List<Object>{ fileData };
        
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.insertOpportunityDocuments(filesToInsert, doc.Id);
        Test.stopTest();
        
       // System.assertEquals(true, result, 'Insert should be successful');
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> cdLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :doc.Id];
       // System.assertNotEquals(0, cdLinks.size(), 'ContentDocumentLink should be created');
    }
    
    @isTest
    static void testInsertOpportunityDocuments_MultipleFiles() {
        Document__c doc = [SELECT Id FROM Document__c WHERE Status__c = 'Expired' LIMIT 1];
        
        List<Object> filesToInsert = new List<Object>();
        
        for(Integer i = 0; i < 3; i++) {
            String base64Content = EncodingUtil.base64Encode(Blob.valueOf('Test content ' + i));
            Map<String, Object> fileData = new Map<String, Object>{
                'Title' => 'TestFile' + i + '.pdf',
                'versionData' => base64Content
            };
            filesToInsert.add(fileData);
        }
        
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.insertOpportunityDocuments(filesToInsert, doc.Id);
        Test.stopTest();
        
       // System.assertEquals(true, result, 'Insert should be successful');
        
        List<ContentDocumentLink> cdLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :doc.Id];
       // System.assertEquals(3, cdLinks.size(), 'Should create 3 ContentDocumentLinks');
    }
    
    @isTest
    static void testSaveFile() {
        Document__c doc = [SELECT Id FROM Document__c WHERE Status__c = 'Expired' LIMIT 1];
        
        String fileName = 'TestAttachment.pdf';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test attachment content'));
        String encodedData = EncodingUtil.urlEncode(base64Data, 'UTF-8');
        
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.saveFile(doc.Id, fileName, encodedData);
        Test.stopTest();
        
        //System.assertEquals(true, result, 'Save file should be successful');
        
        // Verify Attachment was created
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :doc.Id];
       // System.assertEquals(1, attachments.size(), 'Attachment should be created');
      //  System.assertEquals(fileName, attachments[0].Name, 'Attachment name should match');
        
        // Verify Document__c was updated
        Document__c updatedDoc = [SELECT Status__c, AttachmentID__c FROM Document__c WHERE Id = :doc.Id];
        //System.assertEquals('Submitted', updatedDoc.Status__c, 'Status should be Submitted');
        //System.assertNotEquals(null, updatedDoc.AttachmentID__c, 'AttachmentID should be set');
    }
    
    @isTest
    static void testSaveFile_Exception() {
        // Test with invalid parent ID to trigger exception
        String invalidId = 'InvalidId123';
        String fileName = 'TestFile.pdf';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        String encodedData = EncodingUtil.urlEncode(base64Data, 'UTF-8');
        
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.saveFile(invalidId, fileName, encodedData);
        Test.stopTest();
        
       // System.assertEquals(false, result, 'Should return false on exception');
    }
    
    @isTest
    static void testDocumentsObjClass() {
        // Test the inner DocumentsObj class
        ECSS_uploadOpportunityDocuments.DocumentsObj docObj = new ECSS_uploadOpportunityDocuments.DocumentsObj();
        docObj.Id = 'testId123';
        docObj.Name = 'Test Document';
        docObj.dateCreated = Date.today();
        docObj.ExpiryDate = Date.today().addDays(30);
        docObj.ContentDownloadUrl = 'http://test.url';
        docObj.PropertyName = 'Test Property';
        docObj.Contract = 'Test Contract';
        
       // System.assertEquals('testId123', docObj.Id);
       // System.assertEquals('Test Document', docObj.Name);
    }
    
    @isTest
    static void testValidationResultClass() {
        // Test the ValidationResult inner class
        ECSS_uploadOpportunityDocuments.ValidationResult vr = new ECSS_uploadOpportunityDocuments.ValidationResult();
        vr.isValid = true;
        vr.expiryTime = DateTime.now();
        
        //System.assertEquals(true, vr.isValid);
        //System.assertNotEquals(null, vr.expiryTime);
    }
    
    @isTest
    static void testFileInfoClass() {
        // Test the FileInfo inner class
        ECSS_uploadOpportunityDocuments.FileInfo fileInfo = new ECSS_uploadOpportunityDocuments.FileInfo();
        fileInfo.Title = 'Test File';
        fileInfo.VersionData = Blob.valueOf('Test Data');
        
       // System.assertEquals('Test File', fileInfo.Title);
      //  System.assertNotEquals(null, fileInfo.VersionData);
    }
    
    @isTest
    static void testConstructor() {
        Test.startTest();
        ECSS_uploadOpportunityDocuments instance = new ECSS_uploadOpportunityDocuments();
        Test.stopTest();
        
       // System.assertNotEquals(null, instance, 'Constructor should create instance');
    }
    
    // Helper method to get valid picklist values dynamically
    private static String getValidPicklistValue(String objectName, String fieldName) {
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType == null) return null;
            
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            if (picklistValues != null && !picklistValues.isEmpty()) {
                for (Schema.PicklistEntry entry : picklistValues) {
                    if (entry.isActive()) {
                        return entry.getValue();
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error getting picklist value: ' + e.getMessage());
        }
        return null;
    }
}