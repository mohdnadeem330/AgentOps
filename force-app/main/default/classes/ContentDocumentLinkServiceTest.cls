@isTest
public class ContentDocumentLinkServiceTest {
    @IsTest public static void testDocumentService() {

        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Case cs = TestObjectsFactory.getCase(account.Id, con.Id, 'Compliance');
        insert cs;

        Case cs1 = TestObjectsFactory.getCase(account.Id, con.Id, 'Compliance');
        insert cs1;

        ContentVersion content = new ContentVersion(); 
        content.Title = 'Header_Picture1'; 
        content.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        
        ContentVersion content1 = new ContentVersion(); 
        content1.Title = 'Header_Picture12'; 
        content1.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob1 = Blob.valueOf('Unit Test ContentVersion Body1'); 
        content1.VersionData = bodyBlob1; 
        //content.LinkedEntityId=sub.id;
        content1.origin = 'H';
        insert content1;

        List<ContentVersion> files = new List<ContentVersion>();
        files.add(content1);

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = cs.id;
        contentlink.contentdocumentid = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';               
        insert contentlink;

        Set<Id> caseSet = new Set<Id>();
        caseSet.add(cs.Id);

        String getContentDocumentLinkRecord = ContentDocumentLinkService.getContentDocumentLinkRecord(contentlink.LinkedEntityId);
        List<ContentDocumentLink> getAllContentDocumentLinkRecord =  ContentDocumentLinkService.getAllContentDocumentLinkRecord(cs.Id);
        List<ContentDocumentLink> fetchFiles = ContentDocumentLinkService.fetchFiles(cs.Id);
        List<String> fetchTitle = ContentDocumentLinkService.fetchTitle(cs.Id);
        Map<Id,ContentDocumentLink> getLatestDocumentByParentId = ContentDocumentLinkService.getLatestDocumentByParentId(caseSet);
        ContentDocumentLinkService.createContentDocumentLinks(files, cs1.Id);
        ContentDocumentLinkService.getIdUSLMap(new List<Id>{cs.Id});

    }
}