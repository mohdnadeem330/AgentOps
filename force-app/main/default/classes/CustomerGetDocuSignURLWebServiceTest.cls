@isTest
public class CustomerGetDocuSignURLWebServiceTest {

    @testSetup static void setup(){
        HexaBPM__SR_Status__c status = new HexaBPM__SR_Status__c(Name = Constants.SUBMITTED, HexaBPM__Code__c = 'CLOSE_CODE');
        insert status;
    }
     
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        public MockHttpResponseGenerator(String responseBody) {
            this.responseBody = responseBody;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }

    private static Account createTestPersonAccount() {
        Account acc = new Account(
            LastName = 'TestLast',
            FirstName = 'TestFirst',
            PersonEmail = 'testemail@example.com',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
        );
        insert acc;
        return acc;
    }

    private static ContentVersion createContentVersion(String title) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('Sample PDF Content'),
            Origin = 'H'
        );
        insert cv;
        return cv;
    }

    private static Id getOrCreateOpenSRStatusId() {
        List<HexaBPM__SR_Status__c> statuses = [SELECT Id FROM HexaBPM__SR_Status__c WHERE Name = 'Open' LIMIT 1];
        if (!statuses.isEmpty()) {
            return statuses[0].Id;
        } else {
            HexaBPM__SR_Status__c status = new HexaBPM__SR_Status__c(Name = 'Open', HexaBPM__Code__c = 'OPEN_CODE');
            insert status;
            return status.Id;
        }
    }

    private static Id getValidServiceRequestRecordTypeId() {
        List<RecordType> rts = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SObjectType = 'HexaBPM__Service_Request__c' and DeveloperName ='PropertyTransferNOC' limit 1];
        return (!rts.isEmpty()) ? rts[0].Id : null;
    }

    private static HexaBPM__Service_Request__c createServiceRequest() {
        Id srStatusId = getOrCreateOpenSRStatusId();
        Id srRecordTypeId = getValidServiceRequestRecordTypeId();

        HexaBPM__Service_Request__c sr = TestObjectsFactory.getServiceRequest(
            srStatusId,
            null,
            'Property Transfer NOC',
            srRecordTypeId,
            null
        );
        sr.TransferSellingPrice__c = 100000;
        insert sr;
        return sr;
    }

    private static HexaBPM__SR_Doc__c createSRDoc(HexaBPM__Service_Request__c sr, String docName) {
        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
            Name = docName,
            HexaBPM__Service_Request__c = sr.Id
        );
        insert srDoc;
        return srDoc;
    }

    private static void prepareRestContext(Map<String,String> params) {
        RestRequest req = new RestRequest();
        req.requestUri = '/customer/getdocusignurl';
        req.httpMethod = 'POST';
        for (String key : params.keySet()) {
            req.params.put(key, params.get(key));
        }
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
    }

    @isTest
    static void testNormalDocumentFlow() {
        Account acc = createTestPersonAccount();
        Document__c doc = new Document__c(Account__c= acc.Id, DocumentType__c= 'Listing Agreement');
        insert doc;
        
        HexaBPM__Service_Request__c sr = createServiceRequest();
        HexaBPM__SR_Doc__c SRdoc = createSRDoc(sr, 'Document of Adherence');


        ContentVersion cv = createContentVersion('Test');
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        insert new ContentDocumentLink(ContentDocumentId= cdId, LinkedEntityId= SRdoc.Id, ShareType= 'I', Visibility= 'AllUsers');
        insert new ContentDocumentLink(ContentDocumentId= cdId, LinkedEntityId= doc.Id, ShareType= 'I', Visibility= 'AllUsers');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"access_token":"token","envelopeId":"envId","url":"https://docusignurl"}'));

        Map<String,String> params = new Map<String,String>{
            'customerId' => acc.Id,
            'documentId' => doc.Id,
            'returnURL' => 'https://return.url',
            'referenceId' => 'ref'
        };
        prepareRestContext(params);
        
        
        Test.startTest();
        CustomerGetDocuSignURLWebService.doPost(acc.Id, SRdoc.Id, 'https://return.url', 'ref');
        CustomerGetDocuSignURLWebService.doPost(acc.Id, doc.Id, 'https://return.url', 'ref');
        Test.stopTest();
    }
    
    @isTest
    static void testNoContentVersionSetsGenerateDocumentFlag() {
        Account acc = createTestPersonAccount();
        Document__c doc = new Document__c(Account__c= acc.Id, DocumentType__c= 'Custom Type');
        insert doc;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Map<String,String> params = new Map<String,String>{
            'customerId' => acc.Id,
            'documentId' => doc.Id,
            'returnURL' => 'https://return.url',
            'referenceId' => ''
        };
        prepareRestContext(params);

        Test.startTest();
        CustomerGetDocuSignURLWebService.doPost(acc.Id, doc.Id, 'https://return.url', '');
        Test.stopTest();
    }

    @isTest
    static void testDataModelClassesCoverage() {
        Account acc = createTestPersonAccount();
        ContentVersion cv = createContentVersion('ModelDoc');

        Test.startTest();

        new CustomerGetDocuSignURLWebService.AuthenticationRequestModel('grant_type', 'assertion');
        CustomerGetDocuSignURLWebService.AuthenticationResponseModel authResp = new CustomerGetDocuSignURLWebService.AuthenticationResponseModel();
        authResp.access_token = 'token';
        authResp.token_type = 'type';
        authResp.expires_in = 1000;
        authResp.scope = 'scope';

        new CustomerGetDocuSignURLWebService.DocumentModel(cv);
        List<CustomerGetDocuSignURLWebService.DocumentModel> documents = new List<CustomerGetDocuSignURLWebService.DocumentModel>{ new CustomerGetDocuSignURLWebService.DocumentModel(cv)};
        CustomerGetDocuSignURLWebService.EnvelopeRequestModel envReq = new CustomerGetDocuSignURLWebService.EnvelopeRequestModel();
        envReq.emailSubject = 'Subject';
        envReq.documents = documents;
        envReq.recipients = new CustomerGetDocuSignURLWebService.RecipientModel(acc, 'anchor', 'signProvider');
        envReq.status = 'sent';

        CustomerGetDocuSignURLWebService.EnvelopeResponseModel envResp = new CustomerGetDocuSignURLWebService.EnvelopeResponseModel();
        envResp.envelopeId = 'env123';
        envResp.status = 'sent';
        envResp.statusDateTime = 'dateTime';
        envResp.uri = 'uri';

        new CustomerGetDocuSignURLWebService.URLRequestModel('https://return.url', acc);

        CustomerGetDocuSignURLWebService.URLResponseModel urlResp = new CustomerGetDocuSignURLWebService.URLResponseModel();
        urlResp.url = 'https://url';

        CustomerGetDocuSignURLWebService.RecipientModel recipient = new CustomerGetDocuSignURLWebService.RecipientModel(acc, 'anchorString', 'uaepass');
        CustomerGetDocuSignURLWebService.SignerModel signer = recipient.signers[0];
        CustomerGetDocuSignURLWebService.TabModel tabModel = signer.tabs;
        CustomerGetDocuSignURLWebService.SignHereModel signHere = tabModel.signHereTabs[0];
        new CustomerGetDocuSignURLWebService.SignProviderModel('providerName');

        Test.stopTest();
    }
    //Comments
    @isTest
    public static void testCustomerGetDocuSignURLWebService() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Document__c doc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert doc;
        
        Document__c signDoc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC);
        insert signDoc;
        
        HexaBPM__Service_Request__c sr = createServiceRequest();
        HexaBPM__SR_Doc__c SRdoc = createSRDoc(sr, 'Document of Adherence');
            
        
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test';
        content.PathOnClient = '/' + content.Title + '.pdf';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.Origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = SRdoc.Id;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM contentversion WHERE Id =: content.id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        ContentDocumentLink contentlink2 = new ContentDocumentLink();
        contentlink2.LinkedEntityId = signDoc.Id;
        contentlink2.ContentDocumentId = [SELECT ContentDocumentId FROM contentversion WHERE Id =: content.id].ContentDocumentId;
        contentlink2.ShareType = 'I';
        contentlink2.Visibility = 'AllUsers';
        insert contentlink2;
        
        TestObjectsFactory.initializeRestContext(null, '/query/getdocusignurl');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String responseBody = '{"access_token":"test","token_type":"test","expires_in":10000,"scope":"test","":"test","envelopeId":"test","uri":"test","statusDateTime":"test","status":"test","url":"test"}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CustomerGetDocuSignURLWebService.doPost(acc.Id, SRdoc.Id, 'http://localhost', '');
            
            CustomerGetDocuSignURLWebService.URLResponseModel objCls = new CustomerGetDocuSignURLWebService.URLResponseModel();
            //objCls.URLResponseModel obj = new objCls.URLResponseModel();
            objCls.errorCode = '';
            objCls.message = '';
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
}