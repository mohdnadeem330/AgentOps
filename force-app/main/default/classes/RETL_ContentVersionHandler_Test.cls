@IsTest
public class RETL_ContentVersionHandler_Test {

     @testSetup
    static void setupData() {
        
       // Get Record Type Ids
       Map<String, Schema.RecordTypeInfo> rtInfo = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName();

        Id rtRDD = rtInfo.get('RDD_Document') != null ? rtInfo.get('RDD_Document').getRecordTypeId(): null;
        Id srRETL = rtInfo.get('SR_Retail') != null ? rtInfo.get('SR_Retail').getRecordTypeId(): null;


         // Account for Contact
        Account acc = new Account(Name = 'Test Tenant');
        insert acc;
        
        // Contact used via RETL_Tenant__c lookup
        Contact tenantContact = new Contact(
            FirstName = 'Test',
            LastName = 'Tenant',
            Email = 'tenant@test.com',
            AccountId = acc.id
        );
        insert tenantContact;
        
         // Service Request linking to Contact
        RETL_Service_Request__c sr = new RETL_Service_Request__c(
            RETL_Tenant__c = tenantContact.Id
        );
        insert sr;
        
        // Stage used in push notification logic
        RETL_Stage__c stage = new RETL_Stage__c(
            Name = 'Stage Test',
            RETL_Service_RequestId__c = sr.Id,
            RETL_Stage_Developer_Name__c = 'MEP_Design' // must match allowed values
        );
        insert stage;
        
        //Create Document
        Document__c doc = new Document__c(
        DocumentType__c = 'Test Document',
            Status__c = 'uploaded',
            RETL_Stage__c = stage.Id,
            RecordTypeId = (rtRDD != null ? rtRDD : srRETL)
        );
        insert doc;
        
         //Create Content Note for mapping
        ContentNote note = new ContentNote(
            Title = 'Sample Note',
            Content = Blob.valueOf('Some content')
        );
        insert note;
    }
    
     @IsTest
    static void testAfterInsert_Handler() {
        
         // Get required records from test setup
        Document__c doc = [SELECT Id,RETL_Stage__r.Id FROM Document__c WHERE RecordType.DeveloperName IN ('RDD_Document', 'SR_Retail') LIMIT 1];
        ContentNote note = [SELECT Id FROM ContentNote LIMIT 1];

         //Insert ContentVersion to trigger afterInsert Handler
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Sample file'),
            FirstPublishLocationId = doc.Id,          
            RETL_Generate_External_URL__c = true,     
            RETL_ContentNoteId__c = note.Id           
        );
        insert cv;
        
        //ContentDistribution is created by the handler
        List<ContentDistribution> distRecords = [
            SELECT Id, ContentVersionId, ContentDownloadUrl, DistributionPublicUrl
            FROM ContentDistribution
            WHERE ContentVersionId = :cv.Id
        ];

        System.assertEquals(1, distRecords.size(),
            'Handler should create a ContentDistribution record.'
        );
        
        //External_Files__c record created and related values populated
        List<External_Files__c> fileRecords = [
            SELECT Id, File_Name__c, External_URL__c, Document__c, RETL_Case_Comment_SF_ID__c
            FROM External_Files__c
            WHERE Document__c = :doc.Id
        ];

        System.assertEquals(1, fileRecords.size(),
            'Handler should create an External_Files__c record.'
        );

        External_Files__c newFile = fileRecords[0];
        
        //Validate field mapping
        System.assertEquals('Test File', newFile.File_Name__c,
            'File name should match ContentVersion Title'
        );
        System.assertEquals(doc.Id, newFile.Document__c,
            'Document__c should match the FirstPublishLocationId'
        );
        System.assertEquals(note.Id, newFile.RETL_Case_Comment_SF_ID__c,
            'ContentNote reference should be mapped correctly'
        );
        System.assertNotEquals(null, newFile.External_URL__c,
            'External URL should be populated by handler.'
        );
    }
  /*  
  @IsTest
static void testSendPushNotificationFromNotes() {

    // Fetch Document with relationships
    Document__c doc = [
        SELECT Id,
               RETL_Stage__r.Id,
               RETL_Stage__r.RETL_Stage_Developer_Name__c,
               RETL_Stage__r.RETL_Service_RequestId__r.RETL_Tenant__r.Email,
               RETL_Stage__r.RETL_Service_RequestId__r.RETL_Tenant__r.Account.Name
        FROM Document__c
        WHERE RecordType.DeveloperName = 'RDD_Document'
        LIMIT 1
    ];

    // Create Content NOTE
    ContentNote note = new ContentNote(
        Title   = 'Push Note',
        Content = Blob.valueOf('Test push notification')
    );
    insert note;

    // Get auto-created ContentVersion (SNOTE)
    ContentVersion cv = [
        SELECT Id, FileType, ContentDocumentId
        FROM ContentVersion
        WHERE FileType = 'SNOTE'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    // Correct way to attach NOTE to Document__c
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = cv.ContentDocumentId,
        LinkedEntityId    = doc.Id,
        ShareType         = 'V',
        Visibility        = 'AllUsers'
    );
    insert cdl;

    // Re-query to pass fresh instance
    ContentVersion refreshedCv = [
        SELECT Id, FileType, FirstPublishLocationId,ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];

    Test.startTest();
    RETL_ContentVersionHandler.sendPushNotificationFromNotes(
        new List<ContentVersion>{ refreshedCv }
    );
    Test.stopTest();

    System.assertEquals('SNOTE', refreshedCv.FileType);
}
*/
    }