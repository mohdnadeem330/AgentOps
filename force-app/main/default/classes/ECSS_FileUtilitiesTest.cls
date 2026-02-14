@isTest
public class ECSS_FileUtilitiesTest {
    @isTest
    static void testCreateFile() {
        String base64data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String filename = 'TestFile.txt';

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Test.startTest();
        String contentDocumentLinkId = ECSS_FileUtilities.createFile(base64data, filename, testAccount.Id);
        Test.stopTest();

        List<ContentVersion> contentVersions = [
            SELECT Id, Title, PathOnClient, VersionData
            FROM ContentVersion
            WHERE Title = :filename
        ];
        System.assertEquals(1, contentVersions.size(), 'One ContentVersion should be created');
        System.assertEquals(filename, contentVersions[0].Title, 'The file title should match the given filename');

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ShareType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'One ContentDocumentLink should be created');
        System.assertEquals(testAccount.Id, contentDocumentLinks[0].LinkedEntityId, 'The LinkedEntityId should match the test record ID');
        System.assertEquals('V', contentDocumentLinks[0].ShareType, 'The ShareType should be "V"');
    }

  
}