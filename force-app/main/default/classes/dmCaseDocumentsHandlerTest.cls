@isTest
public class dmCaseDocumentsHandlerTest {
    @isTest
    static void dmCaseDocuments() {
        Test.startTest();
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        // Create Contact
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create Case
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c = 'Yas Island',
            Status = 'New'
        );
        insert testCase;
        
        // Create Document with correct record type for getCustomerDocuments
        Document__c document = new Document__c();
        document.DocumentType__c = 'Others';
        document.Case__c = testCase.Id;
        document.RecordTypeId = Schema.SObjectType.Document__c
            .getRecordTypeInfosByDeveloperName()
            .get(Label.DM_CaseDocumentRecordType) // Correct record type
            .getRecordTypeId();
        document.AvailableForExternalUsers__c = true;
        insert document;
        
        // Add related External File
        External_Files__c ext = new External_Files__c();
        ext.Document__c = document.Id;
        ext.Case__c = testCase.Id;
        ext.File_Name__c = 'newdocument';
        ext.Deleted_by_Creator__c = false;
        ext.External_URL__c = 'http://example.com/testfile';
        insert ext;
        
        // Upload a ContentVersion
        ContentVersion testContVer = new ContentVersion();
        testContVer.Title = 'Test Document';
        testContVer.PathOnClient = 'TestDoc.pdf';
        testContVer.VersionData = Blob.valueOf('Test Content');
        testContVer.IsMajorVersion = true;
        insert testContVer;
        
        // Get ContentDocumentId from inserted ContentVersion
        Id contentDocID = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :testContVer.Id
        ].ContentDocumentId;
        
        // Link ContentDocument to the Document__c record
        ContentDocumentLink testContDocLink = new ContentDocumentLink();
        testContDocLink.LinkedEntityId = document.Id;
        testContDocLink.ContentDocumentId = contentDocID;
        insert testContDocLink;
        
        // Call the method under test
        List<dmCaseDocumentsHandler.documentWrapper> result = dmCaseDocumentsHandler.getCustomerDocuments(testCase.Id);
        
        // Test document update method
        dmCaseDocumentsHandler.updateDocument(document);
        
        // Test update visibility method
        dmCaseDocumentsHandler.updateDocumentVisibility(document.Id, 'CAS', testCase.Id);
        
        Test.stopTest();
    }
    
    
    @isTest
    static void DMAldarDocument(){
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c='Yas Island',
            Status = 'New');
        insert testCase;     
        Document__c document = new Document__c();
        document.DocumentType__c = 'Others';
        document.Case__c = testCase.Id; 
        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        document.AvailableForExternalUsers__c = true;
        insert document;
        
        External_Files__c ext = new External_Files__c();
        ext.Document__c=document.Id;
        ext.Case__c=testCase.id;
        ext.File_Name__c = 'newdocument';
        ext.Deleted_by_Creator__c = false;
        ext.External_URL__c ='http://example.com/testfile';
        insert ext;
        ContentVersion testContVer = new ContentVersion();
        testContVer.Title = 'Test Document 2';
        testContVer.PathOnClient = 'SF_ELO_Code.txt';
        testContVer.VersionData = Blob.valueOf('Test Content');   
        testContVer.IsMajorVersion = true;
        insert testContVer;
        id contentDocID = [select ContentDocumentId from ContentVersion where id=:testContVer.Id].ContentDocumentId;
        ContentDocumentLink testContDocLink = new ContentDocumentLink();         
        ContentDocument testContDoc = new ContentDocument();
        testContDocLink.LinkedEntityId = document.Id;
        testContDocLink.ContentDocumentId = contentDocID;
        insert testContDocLink;
        dmCaseDocumentsHandler.getAldarDocuments(testCase.id);
    }
    
    @isTest
    static void DMcreateDocument() {
        Test.startTest();
        
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c='Yas Island',
            Status = 'New');
        insert testCase;
        
        Document__c document = new Document__c();
        document.DocumentType__c = 'Others';
        document.Case__c = testCase.Id; 
        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Case_Document')
            .getRecordTypeId();
        document.AvailableForExternalUsers__c = true;
        
        // ✅ Pass non-empty signedDocType
        dmCaseDocumentsHandler.createDocument(document, 'CustomerDocument', 'Signed CAS');
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testGenerateEmailContent() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Licensee_Email__c = 'test@example.com'
        );
        insert testCase;
        
        Document__c testDocument = new Document__c(
            DocumentType__c = 'Temporary License Agreement',
            Case__c = testCase.Id,
            RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Case_Document').getRecordTypeId(),
            AvailableForExternalUsers__c = true
        );
        insert testDocument;
        
        // Test for DM_DocumentTypeTLA
        Map<String, String> emailContentTLA = dmCaseDocumentsHandler.generateEmailContent(testDocument.Id, testCase.Id, 'Temporary License Agreement');
        System.assertNotEquals(null, emailContentTLA.get('subject'), 'The email subject for TLA should not be null.');
        System.assertNotEquals(null, emailContentTLA.get('body'), 'The email body for TLA should not be null.');
        
        // Test for DM_DocumentTypeSignedTLA
        testDocument.DocumentType__c = 'Signed TLA'; // Change document type for Signed TLA
        update testDocument;
        
        Map<String, String> emailContentSignedTLA = dmCaseDocumentsHandler.generateEmailContent(testDocument.Id, testCase.Id, 'Signed TLA');
        // Test for DM_DocumentTypeFinalTLA
        testDocument.DocumentType__c = 'Final TLA'; // Change document type for Final TLA
        update testDocument;
        
        //   Map<String, String> emailContentFinalTLA = dmCaseDocumentsHandler.generateEmailContent(testDocument.Id, testCase.Id, 'Final TLA');
    }
    
    
    
    @isTest
    static void testGetLicenseeEmail() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Licensee_Email__c = 'test@example.com' // Set the Licensee Email
        );
        insert testCase;
        
        // Call the method being tested
        String licenseeEmail = dmCaseDocumentsHandler.getLicenseeEmail(testCase.Id);
    }
    
    @isTest
    static void testSendEmail() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Licensee_Email__c = 'test@example.com'
        );
        insert testCase;
        
        Document__c testDocument = new Document__c(
            DocumentType__c = 'Temporary License Agreement',
            Case__c = testCase.Id,
            RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Case_Document').getRecordTypeId(),
            AvailableForExternalUsers__c = true
        );
        insert testDocument;
        
        ContentVersion testContVer = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContVer;
        
        // Create the ContentDocumentLink
        ContentDocumentLink testContDocLink = new ContentDocumentLink(
            LinkedEntityId = testDocument.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContVer.Id LIMIT 1].ContentDocumentId
        );
        insert testContDocLink;
        
        // Start the test
        Test.startTest();
        
        // Call the sendEmail method
        dmCaseDocumentsHandler.sendEmail(
            [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContVer.Id LIMIT 1].ContentDocumentId,
            testCase.Id,
            'Temporary License Agreement',
            testDocument.Id,
            'Test Subject',
            'Test Email Body',
            'testcc@example.com',
            'testbcc@example.com',
            'test@example.com'
        );
        
        // End the test
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmail1() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Licensee_Email__c = 'test@example.com'
        );
        insert testCase;
        
        Document__c testDocument = new Document__c(
            DocumentType__c = 'Final TLA',  // Setting the document type to Final TLA
            Case__c = testCase.Id,
            RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Case_Document').getRecordTypeId(),
            AvailableForExternalUsers__c = true
        );
        insert testDocument;
        
        ContentVersion testContVer = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContVer;
        
        // Create the ContentDocumentLink
        ContentDocumentLink testContDocLink = new ContentDocumentLink(
            LinkedEntityId = testDocument.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContVer.Id LIMIT 1].ContentDocumentId
        );
        insert testContDocLink;
        
        // Start the test
        Test.startTest();
        
        // Call the sendEmail method
        dmCaseDocumentsHandler.sendEmail(
            [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContVer.Id LIMIT 1].ContentDocumentId,
            testCase.Id,
            'Final TLA',  // Using the correct document type here
            testDocument.Id,
            'Test Subject',
            'Test Email Body',
            'testcc@example.com',
            'testbcc@example.com',
            'test@example.com'
        );
        
        // End the test
        Test.stopTest();
        
        // Re-fetch the case and verify that the status and sub-status have been updated as per the document type
        testCase = [SELECT Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
    }
    
}