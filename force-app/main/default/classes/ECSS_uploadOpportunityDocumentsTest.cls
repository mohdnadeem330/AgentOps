@isTest
public class ECSS_uploadOpportunityDocumentsTest {

   @isTest
static void testGetOpportunityDocuments() {
    // Fetch the first valid picklist value
   /* String validSubType = '';
    Schema.DescribeFieldResult fieldDescribe = Document__c.ECSS_SubType__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();*/
    
    // Ensure we get a non-empty value
   /* for (Schema.PicklistEntry entry : picklistValues) {
        if (!entry.isDefaultValue()) {
            validSubType = entry.getValue();
            break;
        }
    }*/

  //  System.debug(' Valid SubType: ' + validSubType);
   // System.assertNotEquals('', validSubType, 'No valid picklist value found for ECSS_SubType__c');

    // Create test opportunity
    Opportunity testOpp = new Opportunity(
        Name = 'Test Opportunity', 
        CloseDate = Date.today(), 
        StageName = 'Prospecting'
    );
    insert testOpp;
RecordType brokerDocRT = [
    SELECT Id 
    FROM RecordType 
    WHERE DeveloperName = 'BrokerDocuments' 
        AND SObjectType = 'Document__c' 
    LIMIT 1
];
    // Use the validSubType here 
    Document__c doc1 = new Document__c(
        Opportunity__c = testOpp.Id, 
        Status__c = 'pending', 
        DocumentType__c = 'Power of Attorney and/or Authorization Letter',
       // ECSS_SubType__c = validSubType
        ECSS_SubType__c = 'Power of Attorney and/or Authorization Letter - Power of Attorney and/or Authorization Letter',
        RecordTypeId = brokerDocRT.Id
    );
    insert doc1;

    // You can reuse validSubType or check other values for doc2 if needed
    Document__c doc2 = new Document__c(
        Opportunity__c = testOpp.Id, 
        Status__c = 'Invalid Document', 
        DocumentType__c = 'Power of Attorney and/or Authorization Letter',
        ECSS_SubType__c = 'Power of Attorney and/or Authorization Letter - Power of Attorney and/or Authorization Letter',
         RecordTypeId = brokerDocRT.Id
    );
    insert doc2;

    // Call method and validate results
    Test.startTest();
   // String query = 'SELECT ECSS_SubType__c, Status__c, DocumentType__c FROM Document__c  WHERE Opportunity__c =:'+ testOpp.Id +' AND (Status__c = \'pending\' OR Status__c =\'Invalid Document\')';// wrong 
String query = 'SELECT ECSS_SubType__c, Status__c, DocumentType__c FROM Document__c ' +
               'WHERE Opportunity__c = \'' + testOpp.Id + '\' ' +
               'AND (Status__c = \'pending\' OR Status__c = \'Invalid Document\')';
    String result = ECSS_uploadOpportunityDocuments.getOpportunityDocuments(testOpp.Id, query);
    Test.stopTest();

    system.debug('Result: ' + result);
    System.assert(result != null, 'Expected result string');
}

    @isTest
    static void testInsertOpportunityDocuments() {
        // Prepare test data for the insertOpportunityDocuments method
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting'
        );
        insert testOpp;
        
        // Create a mock file to insert
        Map<String, Object> fileData = new Map<String, Object>();
        fileData.put('Title', 'TestFile.pdf');
        fileData.put('versionData', EncodingUtil.base64Encode(Blob.valueOf('test content')));

        List<Object> filesToInsert = new List<Object>();
        filesToInsert.add(fileData);

        String docId = testOpp.Id;

        // Call method and validate results
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.insertOpportunityDocuments(filesToInsert, docId);
        Test.stopTest();

        // Assert if insertion was successful
        System.assert(result, 'Document insert failed');
    }

    @isTest
    static void testSaveFile() {
        // Prepare test data for the saveFile method
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting'
        );
        insert testOpp;
        RecordType brokerDocRT = [
        SELECT Id 
        FROM RecordType 
        WHERE DeveloperName = 'BrokerDocuments' 
            AND SObjectType = 'Document__c' 
        LIMIT 1
    ];

    // Create test Document__c
    Document__c testDoc = new Document__c(
        Opportunity__c = testOpp.Id,
        Status__c = 'pending',
        DocumentType__c = 'Power of Attorney and/or Authorization Letter',
        ECSS_SubType__c = 'Power of Attorney and/or Authorization Letter - Power of Attorney and/or Authorization Letter',
        RecordTypeId = brokerDocRT.Id
    );
    insert testDoc;

    // Insert test ContentVersion (represents a file upload)
    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Unit test content')
    );
    insert cv;

    // Get ContentDocumentId (linked behind the scenes to ContentVersion)
    ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    // Link the file to the Document__c record
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = insertedCV.ContentDocumentId,
        LinkedEntityId = testDoc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;

        String parentId = testDoc.Id;
        String fileName = 'TestFile.pdf';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('test content'));

        // Call method and validate results
        Test.startTest();
        Boolean result = ECSS_uploadOpportunityDocuments.saveFile(parentId, fileName, base64Data);
        Test.stopTest();

        // Assert if file save was successful
        System.assert(result);
    }
    
    @isTest
static void testUpdateStatusAndGetRelatedDocs() {
    // Create test Opportunity
    Opportunity testOpp = new Opportunity(
        Name = 'Test Opportunity', 
        CloseDate = Date.today(), 
        StageName = 'Prospecting'
    );
    insert testOpp;

    // Get RecordType
    RecordType brokerDocRT = [
        SELECT Id 
        FROM RecordType 
        WHERE DeveloperName = 'BrokerDocuments' 
            AND SObjectType = 'Document__c' 
        LIMIT 1
    ];

    // Create test Document__c
    Document__c testDoc = new Document__c(
        Opportunity__c = testOpp.Id,
        Status__c = 'pending',
        DocumentType__c = 'Power of Attorney and/or Authorization Letter',
        ECSS_SubType__c = 'Power of Attorney and/or Authorization Letter - Power of Attorney and/or Authorization Letter',
        RecordTypeId = brokerDocRT.Id
    );
    insert testDoc;

    // Insert test ContentVersion (represents a file upload)
    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Unit test content')
    );
    insert cv;

    // Get ContentDocumentId (linked behind the scenes to ContentVersion)
    ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    // Link the file to the Document__c record
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = insertedCV.ContentDocumentId,
        LinkedEntityId = testDoc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;

    // Call method: updateStatus
    Test.startTest();
    String previewUrl = ECSS_uploadOpportunityDocuments.updateStatus(testDoc.Id,Date.today());
    Test.stopTest();
    System.debug('Preview URL: ' + previewUrl);
    System.assert(previewUrl.contains('/sfc/servlet.shepherd/document/download/'), 'Preview URL not formed as expected');

    // Call method: getRelatedVersionOpportunityDocuments
    String dynamicQuery = 'SELECT Id, ECSS_SubType__c, Status__c, DocumentType__c, ECSS_PublicLink__c,ECSS_Expiry_Date_Required__c,ECSS_Expiry_Date__c, ECSS_Required__c FROM Document__c ' +
                          'WHERE Opportunity__c = \'' + testOpp.Id + '\' ' +
                          'AND (Status__c = \'Submitted\' OR Status__c = \'pending\')';
    
    List<Map<String, Object>> relatedDocs = ECSS_uploadOpportunityDocuments.getRelatedVersionOpportunityDocuments(testOpp.Id, dynamicQuery);
    System.debug('Related Docs: ' + relatedDocs);
    System.assert(!relatedDocs.isEmpty(), 'Expected related docs');

    // Call method: getRelatedFilesByRecordId
    List<Id> fileIds = ECSS_uploadOpportunityDocuments.getRelatedFilesByRecordId(testDoc.Id);
    System.debug('File Ids: ' + fileIds);
    System.assert(!fileIds.isEmpty(), 'File IDs should not be empty');
}

}