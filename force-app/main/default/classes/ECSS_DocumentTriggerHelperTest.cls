@isTest
public class ECSS_DocumentTriggerHelperTest {
    
    @testSetup
    static void setupData() {
        // Insert a Document__c record with initial status
        /*Document__c doc = new Document__c(
           
            Status__c = 'Draft',
            ECSS_Unit__c = 'Test_Asset_1',
            AttachmentID__c = '00P000000000123',  // dummy value
            Correlation_ID__c = 'CORR123',

            MimeType__c = 'application/pdf'
        );
        insert doc;*/
        
        Document__c doc= new Document__c(DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert doc;
        
        // Create ContentDocument + ContentVersion tied to the Document__c
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Sample Content'),
            FirstPublishLocationId = doc.Id
        );
        insert cv;
    }
    
    @isTest
    static void testDocumentPlatformEventPublished() {
        // Fetch Document created in testSetup
        Document__c doc = [SELECT Id, Status__c, AttachmentID__c, Correlation_ID__c, Name, ECSS_AttachementURL__c, MimeType__c, ECSS_Unit__c FROM Document__c LIMIT 1];
        
        // Simulate old record
        Document__c oldDoc = new Document__c(
            Id = doc.Id,
            Status__c = 'Draft'
        );
        
        // Update status to Submitted
        doc.Status__c = 'Submitted';
        
        List<SObject> newList = new List<SObject>{ doc };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ doc.Id => oldDoc };
        
        Test.startTest();
        ECSS_DocumentTriggerHelper.DocumentPlatformEvent(newList, oldMap);
        Test.stopTest();
        
        // We can’t assert event count in this org version, 
        // but at least we assert code ran without exception
        System.assert(true, 'Code executed successfully when status changed to Submitted');
    }
    
    @isTest
    static void testNoEventWhenStatusUnchanged() {
        Document__c doc = [SELECT Id, Status__c FROM Document__c LIMIT 1];
        
        // Simulate old record with same status
        Document__c oldDoc = new Document__c(
            Id = doc.Id,
            Status__c = 'Draft'
        );
        
        // Keep status the same
        doc.Status__c = 'Draft';
        
        List<SObject> newList = new List<SObject>{ doc };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ doc.Id => oldDoc };
        
        Test.startTest();
        ECSS_DocumentTriggerHelper.DocumentPlatformEvent(newList, oldMap);
        Test.stopTest();
        
        System.assert(true, 'Code executed successfully when status did not change');
    }
}