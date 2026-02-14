@isTest
public class ECSS_PropertyControllerTest {
@testSetup
static void setupTestData() {
    Account property = new Account(Name = 'Test Property');
    insert property;

    ContentVersion contentVersion = new ContentVersion(
        Title = 'Test Image',
        PathOnClient = 'TestImage.png',
        VersionData = Blob.valueOf('Test Data'),
        FirstPublishLocationId = property.Id
    );
    insert contentVersion;

    ContentVersion insertedContentVersion = [
        SELECT Id, ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :contentVersion.Id
    ];

    List<ContentDocumentLink> existingLinks = [
        SELECT Id 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :property.Id 
        AND ContentDocumentId = :insertedContentVersion.ContentDocumentId
    ];

    if (existingLinks.isEmpty()) {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = property.Id,
            ContentDocumentId = insertedContentVersion.ContentDocumentId,
            ShareType = 'V'
        );
        insert contentDocumentLink;
    }
}

    @isTest
    static void testGetPictures() {
        Account property = [SELECT Id FROM Account WHERE Name = 'Test Property' LIMIT 1];

        Test.startTest();
        List<ContentVersion> pictures = ECSS_PropertyController.getPictures(property.Id);
        Test.stopTest();

        System.assertNotEquals(null, pictures, 'The pictures list should not be null.');
        System.assertEquals(1, pictures.size(), 'The pictures list should contain one entry.');
        System.assertEquals('Test Image', pictures[0].Title, 'The picture title should match the test data.');
    }

    @isTest
    static void testGetPicturesNoLinks() {
        Account propertyWithoutLinks = new Account(Name = 'No Links Property');
        insert propertyWithoutLinks;

        Test.startTest();
        List<ContentVersion> pictures = ECSS_PropertyController.getPictures(propertyWithoutLinks.Id);
        Test.stopTest();

        System.assertEquals(null, pictures, 'The pictures list should be null when no documents are linked.');
    }
}