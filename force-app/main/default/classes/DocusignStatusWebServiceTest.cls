@IsTest
public class DocusignStatusWebServiceTest {
    
    @testSetup
    private static void setupData() {
        
        // Project
        Project__c projectRec = TestObjectsFactory.getProjectRecord('Saadiyat');
        insert projectRec;
        
        Account seller = TestObjectsFactory.getPersonAccountRecord();
        seller.NationalIdNumber__pc = '';
        insert seller;
        
        // Document
        Document__c documentRec = new Document__c(
            Project__c = projectRec.Id,
            DocumentType__c = Constants.DOCUMENT_TYPE_GTC
        );
        insert documentRec;
        
        // Building Section
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(projectRec.Id);
        buildingSection.AldarStaffTransferThresholdLimit__c = 40;
        insert buildingSection;
        
        // Unit
        Unit__c u = TestObjectsFactory.getUnitDetail(projectRec.Id, buildingSection.Id);
        u.Status__c = 'Sold';
        u.BuildingSectionName__c = buildingSection.id;
        insert u;
        
        // Closed status
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');
        insert closed;

        // SPA Registration Service Request
        HexaBPM__Service_Request__c srSpa = new HexaBPM__Service_Request__c(
            RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c
                .getRecordTypeInfosByName().get('SPA Registration For Off Plan').getRecordTypeId(),
            SRType__c = Constants.SPA_REGISTRATION_TYPE,
            Unit__c = u.Id,
            HexaBPM__External_SR_Status__c = closed.Id
        );
        insert srSpa;

        // Property Transfer Service Request
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c
                .getRecordTypeInfosByName().get('Property Transfer (Off Plan)').getRecordTypeId(),
            SRType__c = Constants.PROPERTY_TRANSFER_OffPlan,
            Unit__c = u.Id,
            HexaBPM__Customer__c = seller.Id
        );
        insert sr;

        // --- Document Master & Template ---
        
        HexaBPM__Document_Master__c docMaster = new HexaBPM__Document_Master__c(
            HexaBPM__Code__c = 'Assignment Of Rights',
            HexaBPM__Available_to_client__c = true
        );
        insert docMaster;
        
        HexaBPM__Document_Master__c docMaster2 = new HexaBPM__Document_Master__c(
            HexaBPM__Code__c = 'Signed Assignment Of Rights',
            HexaBPM__Available_to_client__c = true
        );
        insert docMaster2;
        
        HexaBPM__SR_Template_Docs__c srTemplateDoc = new HexaBPM__SR_Template_Docs__c(
            HexaBPM__Document_Master__c = docMaster.Id,
            ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner'
        );
        insert srTemplateDoc;

        HexaBPM__SR_Template_Docs__c srTemplateDoc2 = new HexaBPM__SR_Template_Docs__c(
            HexaBPM__Document_Master__c = docMaster2.Id
        );
        insert srTemplateDoc2;

        // Main document
        HexaBPM__SR_Doc__c mainDoc = new HexaBPM__SR_Doc__c(
            Name = 'Assignment Of Rights',
            HexaBPM__Service_Request__c = sr.Id,
            HexaBPM__SR_Template_Doc__c = srTemplateDoc.Id
        );
        insert mainDoc;

        HexaBPM__SR_Doc__c signedDoc = new HexaBPM__SR_Doc__c(
            Name = 'Signed Assignment Of Rights',
            HexaBPM__Service_Request__c = sr.Id,
            Docusign_Envelope_Id__c = 'DOCUSIGN-ENV-001',
            HexaBPM__SR_Template_Doc__c = srTemplateDoc2.Id
        );
        insert signedDoc;

        // Attach ContentDocument to signedDoc
        ContentVersion cv = new ContentVersion(
            Title = 'SignedDoc',
            PathOnClient = 'SignedDoc.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = signedDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
    }
    

    // Negative Test: Invalid Document Id
    @IsTest
    private static void testInvalidDocumentId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LiveAldar/DocusignStatusWebService';
        req.httpMethod = 'GET';
        req.addParameter('documentId', 'Fake_Doc_ID');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        DocusignStatusWebService.doGet();
        Test.stopTest();
    }

    // Positive Test: Valid Request
    @IsTest
    private static void testSuccessScenario() {
        HexaBPM__SR_Doc__c mainDoc = [
            SELECT Id FROM HexaBPM__SR_Doc__c WHERE Docusign_Envelope_Id__c != NULL LIMIT 1
        ];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LiveAldar/DocusignStatusWebService';
        req.httpMethod = 'GET';
        req.addParameter('documentId', mainDoc.Id);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        DocusignStatusWebService.doGet();
        Test.stopTest();
    }

    // Full Path Test: covers relatedSignDocument
    @IsTest
    private static void testSuccessScenario1() {
        HexaBPM__SR_Doc__c doc = [
            SELECT Id, HexaBPM__Service_Request__c, DocumentMasterCode__c FROM HexaBPM__SR_Doc__c 
            WHERE Docusign_Envelope_Id__c = NULL LIMIT 1
        ];
		system.debug('mainDoc.DocumentMasterCode__c-->'+doc.DocumentMasterCode__c);
        
        ContentDocumentLink contentDocLink= new ContentDocumentLink();
		contentDocLink= TestObjectsFactory.createContentDocumentLink(doc.Id);
        
        insert new AgencyTeam__c(
            Name = 'test',
            ServiceRequest__c = doc.HexaBPM__Service_Request__c,
            Type__c = Constants.AGENCY_ADMIN,
            MobileNumber__c = '971 12345'
        );
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LiveAldar/DocusignStatusWebService';
        req.httpMethod = 'GET';
        req.addParameter('documentId', doc.Id);
        req.addParameter('customerId', acc.Id);
        req.addParameter('returnURL', 'www.google.com');

        RestContext.request = req;
        RestContext.response = res;

        DocusignStatusWebService.doGet();

        Test.stopTest();
    }
}