@isTest
public class ContentVersionServiceTest {
    @IsTest public static void testDocumentService() {

        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;

        ContentVersion content = new ContentVersion(); 
        content.Title = 'Header_Picture1'; 
        content.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = account.id;
        contentlink.contentdocumentid = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';               
        insert contentlink;

        List<Id> fileIDs = new List<Id>();
        fileIDs.add(contentlink.contentdocumentid);

        List<String> lstFileIds = new List<String>();
        lstFileIds.add(content.Id);

        List<ContentVersion> getFileIds = ContentVersionService.getFileIds(fileIDs);

        list<ContentVersion> returnFiles = ContentVersionService.returnFiles(lstFileIds);

        ContentVersion createContentVersion = ContentVersionService.createContentVersion('Header_Picture1', bodyBlob);

    }
}