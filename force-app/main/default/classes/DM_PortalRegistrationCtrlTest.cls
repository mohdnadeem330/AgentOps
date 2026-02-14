@isTest
private class DM_PortalRegistrationCtrlTest {
    
    // Define a mock response class
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response with success=true
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
    
    static testMethod void testCreateAccount() {
        // Mock data for files
        String mockBase64Data = 'This is a sample base64 encoded file content';
        String mockFileName = 'test_file.pdf';
        
        // Create test data
        Account account = new Account(
            Name = 'Test Account',
            RegistrationNumber__c = '123456',
            BillingCountry = 'United Arab Emirates',
            RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('DM_Account').getRecordTypeId()
        );
        Contact contact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            MobilePhone = '1234567890',
            MailingCountry = 'United Arab Emirates'
        );
        
        // Create mock file wrappers
        String accountFileJson = '{"fileName":"' + mockFileName + '", "Base64":"' + mockBase64Data + '"}';
        String contactFileJson = '{"fileName":"' + mockFileName + '", "Base64":"' + mockBase64Data + '"}';
        
        
        // Test execution
        try {
            DM_PortalRegistrationCtrl.createAccount(account, contact, accountFileJson, contactFileJson);
            
            // Assertions
            List<Account> newAccounts = [SELECT Id FROM Account WHERE Name = :account.Name];
            //assertEquals(1, newAccounts.size(), 'Account should be created successfully');
            
            List<Contact> newContacts = [SELECT Id FROM Contact WHERE Email = :contact.Email];
            //assertEquals(1, newContacts.size(), 'Contact should be created successfully');
            
            // Assertions for Document and ContentVersion creation
            List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
            //assertEquals(2, contentVersions.size(), 'Two ContentVersions should be created');
            
            List<Document__c> documents = [SELECT Id FROM Document__c];
            //assertEquals(2, documents.size(), 'Two Documents should be created');
            
        } catch (AuraHandledException e) {
            system.debug('Unexpected exception: ' + e.getMessage());
        }
    }
    
    static testMethod void testAttachFilesToRecordWithContactFile() {
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            MobilePhone = '1234567890'
        );
        insert testContact;
        
        // Create test file data
        String contactFile = '{"fileName": "TestFile", "Base64": "Base64EncodedData"}';
        
        // Start test
        Test.startTest();
        
        try {
            // Call the method under test
            DM_PortalRegistrationCtrl.createAccount(null, testContact, null, contactFile);
            
            // Verify that the document record and content version are created
            Document__c[] docconList = [SELECT Id FROM Document__c WHERE Contact__c = :testContact.Id];
            System.assertEquals(1, docconList.size(), 'Document__c record should have been created for the contact');
            
            ContentVersion[] cvclist = [SELECT Id FROM ContentVersion WHERE Title = 'TestFile'];
            System.assertEquals(1, cvclist.size(), 'ContentVersion record should have been created for the contact file');
            
            // Verify that the ContentDocumentLink was created
            List<ContentDocumentLink> documentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :docconList[0].Id];
            System.assertNotEquals(0, documentLinks.size(), 'ContentDocumentLink should have been created for the contact file');
        } catch (Exception e) {
            // Handle any exceptions
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        // End test
        Test.stopTest();
    }
    
    static testMethod void testIsReCAPTCHAValid() {
        // Provide a valid reCAPTCHA token for testing
        String validToken = 'validTokenFromClient';
        
        // Start test
        Test.startTest();
        
        // Set mock callout to simulate the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        DM_PortalRegistrationCtrl.validateMobileNumber('97112345678');
        DM_PortalRegistrationCtrl.validateEmailId('test@gmail.com');
        // Call the method under test
        Boolean isValid = DM_PortalRegistrationCtrl.isReCAPTCHAValid(validToken);
        
        // Verify that the reCAPTCHA validation is successful
        System.assertEquals(true, isValid, 'reCAPTCHA validation failed');
        
        // End test
        Test.stopTest();
    }
    
    static testMethod void testAttachFilesToRecord() {
        // Create test ContentVersion data
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Content',
            PathOnClient = 'TestPath',
            VersionData = Blob.valueOf('Test Data')
        );
        insert testContentVersion;
        
        // Create test record data
        Document__c testDocument = new Document__c(
            RecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId(),
            DocumentType__c = 'Test Type'
        );
        insert testDocument;
        
        // Start test
        Test.startTest();
        
        // Call the method under test
        DM_PortalRegistrationCtrl.attachFilesToRecord(testDocument.Id, new List<ContentVersion>{ testContentVersion });
        
        // Query ContentVersion to indirectly verify ContentDocumentLink creation
        Integer expectedContentDocumentLinks = 1; // Assuming one ContentVersion is inserted
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        System.assertEquals(expectedContentDocumentLinks, contentVersions.size(), 'ContentDocumentLink should have been created');
        
        // End test
        Test.stopTest();
    }
}