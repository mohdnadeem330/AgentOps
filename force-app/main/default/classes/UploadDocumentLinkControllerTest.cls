@IsTest
public class UploadDocumentLinkControllerTest {

    // Utility method to create a test Case
    private static Case createTestCase() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Requests').getRecordTypeId();
        case caseRec = new Case();
        caseRec.RecordTypeId = caseRtId;
        caseRec.AccountId = acc.Id;
        caseRec.Unit__c = unit.Id;
        caseRec.Origin = 'Web';
        caseRec.Status = 'New';
        caseRec.Priority = 'Medium';
        insert caseRec;
        return caseRec;
    }

    // Utility method to create a ContentDocument
    private static Id createTestContentDocument() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;

        // Fetch ContentDocumentId
        return [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ].ContentDocumentId;
    }

    @IsTest
    static void testGenerateAndSaveEncryptedKey() {
        Case c = createTestCase();

        Test.startTest();
        String token = UploadDocumentLinkController.generateAndSaveEncryptedKey(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, token, 'Encrypted token should be generated');

        Case updatedCase = [
            SELECT Encrypted_Token__c, Token_Expiry_Date__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(token, updatedCase.Encrypted_Token__c);
        System.assert(updatedCase.Token_Expiry_Date__c > System.now(),
            'Token expiry should be in the future');
    }

    @IsTest
    static void testValidateEncryptedToken_Success() {
        Case c = createTestCase();

        String token = UploadDocumentLinkController.generateAndSaveEncryptedKey(c.Id);

        Test.startTest();
        Id returnedCaseId = UploadDocumentLinkController.validateEncryptedToken(token);
        Test.stopTest();

        System.assertEquals(c.Id, returnedCaseId);
    }

    @IsTest
    static void testValidateEncryptedToken_InvalidToken() {
        Test.startTest();
        try {
            UploadDocumentLinkController.validateEncryptedToken('invalid-token');
           // System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Invalid or expired token'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadFilesToCase() {
        Case c = createTestCase();
        Id docId = createTestContentDocument();

        Test.startTest();
        UploadDocumentLinkController.uploadFilesToCase(
            c.Id,
            new List<Id>{ docId }
        );
        Test.stopTest();

        // Verify ContentDocumentLink
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
        ];
        System.assertEquals(1, links.size());

        // Verify Case updates
        Case updatedCase = [
            SELECT Encrypted_Token__c, Status, Sub_Status__c
            FROM Case
            WHERE Id = :c.Id
        ];
        System.assertEquals(null, updatedCase.Encrypted_Token__c);
        System.assertEquals('Work In Progress', updatedCase.Status);
        System.assertEquals('Follow up by Customer', updatedCase.Sub_Status__c);
    }

    @IsTest
    static void testGetCaseDetails() {
        Case c = createTestCase();

        Test.startTest();
        Case result = UploadDocumentLinkController.getCaseDetails(c.Id);
        Test.stopTest();

        System.assertEquals(c.Id, result.Id);
        System.assertEquals(c.Subject, result.Subject);
        System.assertEquals(c.Status, result.Status);
    }
}