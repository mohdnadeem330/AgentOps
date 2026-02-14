@isTest
public class DocuSignMultiBuyerSignerTest {
    
    @testSetup
    public static void testDataSetup(){
        Id personAccountRecordTypeId = Utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account(FirstName='Test', LastName='User', PersonEmail='test@example.com', RecordTypeId=personAccountRecordTypeId);
        insert acc;
        
        Project__c project = TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004';
        unit.Project__c = project.Id;
        insert unit;
        
        HexaBPM__SR_Status__c SRStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert SRStatus;
        
        Id nocRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c(HexaBPM__Active__c = true, HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC');
        insert template;
        
        HexaBPM__Service_Request__c sr = TestObjectsFactory.getServiceRequest(SRStatus.Id, unit.Id, 'Property Transfer NOC', nocRTId, template.Id);
        sr.TransferSellingPrice__c = 1500000;
        sr.HexaBPM__Customer__c = acc.Id;
        insert sr;
        
        /* Joint Owner Partner
AgencyTeam__c partner = new AgencyTeam__c(Account__c = acc.Id, ServiceRequest__c = '');
insert partner; */
        
        // SR Doc for OA
        HexaBPM__Document_Master__c docMaster = new HexaBPM__Document_Master__c(HexaBPM__Code__c = 'Assignment_of_Service_Charge', HexaBPM__Available_to_client__c = true, AvailableForCustomer__c = true);
        insert docMaster;
        
        HexaBPM__SR_Template_Docs__c srTemplateDoc = new HexaBPM__SR_Template_Docs__c(HexaBPM__Document_Master__c = docMaster.Id);
        insert srTemplateDoc;
        
        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
            Name = 'Document of Adherence',
            HexaBPM__Service_Request__c = sr.Id,
            HexaBPM__Document_Master__c = docMaster.Id,
            HexaBPM__SR_Template_Doc__c = srTemplateDoc.Id,
            HexaBPM__Status__c = 'Draft'
            //HexaBPM__Document_Name__c = 'DocName',
            //DocumentMasterCode__c = 'DOC_CODE'
        );
        insert srDoc;
        
         HexaBPM__SR_Doc__c signedDOA = new HexaBPM__SR_Doc__c(
            Name = 'Signed Document of Adherence',
            HexaBPM__Service_Request__c = sr.Id,
            HexaBPM__Document_Master__c = docMaster.Id,
            HexaBPM__SR_Template_Doc__c = srTemplateDoc.Id,
            HexaBPM__Status__c = 'Draft'
            
        );
        insert signedDOA;
        
        // Signed Doc
        HexaBPM__SR_Doc__c signedDoc = new HexaBPM__SR_Doc__c(Name = 'Signed Owner Association Letter', HexaBPM__Service_Request__c = sr.Id);
        insert signedDoc;
        
        ContentVersion content = new ContentVersion(
            Title = 'TestContent',
            PathOnClient = '/TestContent.jpg',
            VersionData = Blob.valueOf('Unit Test ContentVersion Body'),
            Origin = 'H'
        );
        insert content;
        
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = srDoc.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id].ContentDocumentId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert link;
    }
    
    @isTest
    static void testHandleNOCDocuments(){
        List<HexaBPM__SR_Doc__c> srDocs = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE Name = 'Document of Adherence' LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        Organization org = Utilities.getOrganizationDetails();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        DocuSignMultiBuyerSigner.handleNOCDocuments(accounts[0].Id, srDocs[0].Id, 'https://returnurl.com', 'mockAuthToken', org);
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndpoint().contains('Envelope')) {
                res.setBody('{"envelopeId":"testEnvelopeId"}');
            } else if(req.getEndpoint().contains('DosuSignURL')) {
                res.setBody('{"url":"https://docusign.com/someurl"}');
            } else {
                res.setBody('{"access_token":"mocktoken"}');
            }
            return res;
        }
    }
}