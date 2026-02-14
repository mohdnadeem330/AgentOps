@IsTest
private class BP_AdmReracopyexpose_Test {

    @TestSetup
    static void setupTestData() {
        Contact testContact = new Contact(LastName = 'Test User');
        insert testContact;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test data'),
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id
        ];
        Document__c doc1 = new Document__c(
            DocumentType__c = 'ADM Card',
            Contact__c = testContact.Id
        );
        insert doc1;
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = doc1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
    }

    @IsTest
    static void testSuccessfulExecution() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        String body = JSON.serialize(new Map<String, Object>{ 'contactId' => contact.Id });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/agentAdmReraCopy';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_AdmReracopyexpose.execute();
        Test.stopTest();
       // System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testMissingContactId() {
        String body = JSON.serialize(new Map<String, Object>{ });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/agentAdmReraCopy';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_AdmReracopyexpose.execute();
        Test.stopTest();
   //     System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testNoDocumentsFound() {
        Contact contact = new Contact(LastName = 'NoDocs User');
        insert contact;

        String body = JSON.serialize(new Map<String, Object>{ 'contactId' => contact.Id });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/agentAdmReraCopy';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_AdmReracopyexpose.execute();
        Test.stopTest();

      //  System.assertEquals(200, RestContext.response.statusCode);
    }
}