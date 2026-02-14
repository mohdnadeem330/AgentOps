@IsTest
private class BP_getVATDetailsTest {

    @IsTest
    static void testExecute_validRequest() {
        Account acc = new Account(
            Name = 'Test Account',
            UAEVATRegisterNumber__c = 'AB12cdEF345ghIJ',
            VAT_Approval_Status__c = 'SUBMITTED',
            VATRegistrationtype__c = 'VAT Undertaking Certificate',
            ProposedVATStartDate__c = Date.today(),
            ProposedVATExpiryDate__c = Date.today().addYears(1)
        );
        insert acc;

        HexaBPM__Document_Master__c docMaster = new HexaBPM__Document_Master__c(
            Name = 'VAT Registration Certificate',
            HexaBPM__Code__c = 'VAT_CERT_CODE_001',  // required unique code field
            HexaBPM__Available_to_client__c = true
        );
        insert docMaster;

        HexaBPM__SR_Template_Docs__c srTemplateDoc = new HexaBPM__SR_Template_Docs__c(
            HexaBPM__Document_Master__c = docMaster.Id
        );
        insert srTemplateDoc;
        
        HexaBPM__SR_Status__c SRStatus = new HexaBPM__SR_Status__c(Name = Constants.SUBMITTED, HexaBPM__Code__c ='CODE');
        insert SRStatus;

        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            AccountName__c = 'Test SR',
            HexaBPM__External_SR_Status__c = SRStatus.Id,
            HexaBPM__Internal_SR_Status__c = SRStatus.Id
        );
        insert sr;

        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
            HexaBPM__Customer__c = acc.Id,
            Name = 'VAT Registration Certificate',
            HexaBPM__Document_Type__c = 'Type A',
            HexaBPM__SR_Template_Doc__c = srTemplateDoc.Id,
            HexaBPM__Service_Request__c = sr.Id,
            HexaBPM__Document_Master__c = docMaster.Id
        );
        insert srDoc;

        ContentVersion cv = new ContentVersion(
            Title = 'VATCert',
            PathOnClient = 'VATCert.pdf',
            VersionData = Blob.valueOf('Sample VAT Cert Content'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        String contentDocumentId = insertedCV.ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = srDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getVATfilesinformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String requestBody = JSON.serialize(new Map<String, Object>{
            'accountId' => acc.Id
        });
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();


        Test.startTest();
        BP_getVATDetails.execute();
        Test.stopTest();

        String resBody = RestContext.response.responseBody.toString();
        Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(resBody);

       

        Map<String, Object> data = (Map<String, Object>) res.get('data');
        Map<String, Object> file = (Map<String, Object>) data.get('files');

        System.assertEquals(acc.Id, file.get('accountId'));
        System.assertEquals('VATCert', file.get('fileName'));
        System.assertEquals('pdf', file.get('fileExtension'));
    }

    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getVATfilesinformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); // empty body

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_getVATDetails.execute();
        Test.stopTest();

        String resBody = RestContext.response.responseBody.toString();
        Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(resBody);

       
    }

    @IsTest
    static void testExecute_malformedJson() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getVATfilesinformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"accountId": '); // malformed JSON

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_getVATDetails.execute();
        Test.stopTest();

        String resBody = RestContext.response.responseBody.toString();
        Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(resBody);

       
    }
    @IsTest
static void testExecute_noFileLinkedToVATDocument() {
    // Create test Account
    Account acc = new Account(
        Name = 'Test Account No File',
        UAEVATRegisterNumber__c = 'VAT12345678',
        VAT_Approval_Status__c = 'SUBMITTED',
        VATRegistrationtype__c = 'VAT Undertaking Certificate',
        ProposedVATStartDate__c = Date.today(),
        ProposedVATExpiryDate__c = Date.today().addYears(1)
    );
    insert acc;

    // Create Document Master
    HexaBPM__Document_Master__c docMaster = new HexaBPM__Document_Master__c(
        Name = 'VAT Registration Certificate',
        HexaBPM__Code__c = 'VAT_NOFILE_TEST',
        HexaBPM__Available_to_client__c = true
    );
    insert docMaster;

    // Create Template Doc
    HexaBPM__SR_Template_Docs__c srTemplateDoc = new HexaBPM__SR_Template_Docs__c(
        HexaBPM__Document_Master__c = docMaster.Id
    );
    insert srTemplateDoc;

    // Create SR Status
    HexaBPM__SR_Status__c SRStatus = new HexaBPM__SR_Status__c(Name = Constants.SUBMITTED, HexaBPM__Code__c ='CODE2');
    insert SRStatus;

    // Create SR
    HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
        AccountName__c = 'Test SR No File',
        HexaBPM__External_SR_Status__c = SRStatus.Id,
        HexaBPM__Internal_SR_Status__c = SRStatus.Id
    );
    insert sr;

    // Create SR Doc without linking file
    HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
        HexaBPM__Customer__c = acc.Id,
        Name = 'VAT Registration Certificate',
        HexaBPM__Document_Type__c = 'Type B',
        HexaBPM__SR_Template_Doc__c = srTemplateDoc.Id,
        HexaBPM__Service_Request__c = sr.Id,
        HexaBPM__Document_Master__c = docMaster.Id
    );
    insert srDoc;

    // No ContentVersion or ContentDocumentLink inserted here

    // Prepare REST request
    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/getVATfilesinformation';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');
    String requestBody = JSON.serialize(new Map<String, Object>{ 'accountId' => acc.Id });
    req.requestBody = Blob.valueOf(requestBody);

    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_getVATDetails.execute();
    Test.stopTest();

    String resBody = RestContext.response.responseBody.toString();
    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(resBody);

    System.assertEquals(true, res.get('success'));
    System.assertEquals(200, res.get('statusCode'));

    Map<String, Object> data = (Map<String, Object>) res.get('data');
    Map<String, Object> file = (Map<String, Object>) data.get('files');

    //System.assertEquals(acc.Id, file.get('accountId'));
    //System.assertEquals(acc.Name, file.get('accountName'));
   // System.assertEquals('No file linked to VAT document.', file.get('message'));
}

}