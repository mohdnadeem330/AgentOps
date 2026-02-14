@isTest
private class BP_UploadTradeLicenceDocTest {
    
    // 🔹 Utility Method: Setup Test Data
    private static Map<String, Object> setupTestData() {
        Map<String, Object> testData = new Map<String, Object>();

        // Create Account
        Account account = new Account();
      account.RegistrationExpiryDate__c=System.today().addDays(12);
        account.Name = 'Upendra';
      
        insert account;
        testData.put('account', account);

        // Create Contact
        Contact contactRecord = TestObjectsFactory.contactDataSetup(account.Id);
        contactRecord.PrimaryOwner__c = true;
        contactRecord.BrokerType__c = 'Partner/Owner';
        contactRecord.AgentStatus__c = 'Active';
        contactRecord.MobileCountryCode__c = '971';
        contactRecord.MobilePhone__c = '9696859685';
        contactRecord.Email = 'test@gmail.com';
        update contactRecord;
        testData.put('contact', contactRecord);

        // Create Service Request
        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
        insert serviceRequest;
        testData.put('serviceRequest', serviceRequest);

        // Create Document Master
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'PDF';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        objDocMaster.Name = 'Trade/Commercial License';
        insert objDocMaster;
        testData.put('docMaster', objDocMaster);

        // Create Template Document
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.Id;
        insert docTemp;
        testData.put('docTemp', docTemp);

        
        List<HexaBPM__SR_Status__c> HexaBPMSRStatusList = new List<HexaBPM__SR_Status__c>();
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        HexaBPMSRStatusList.add(draft);
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        HexaBPMSRStatusList.add(Submitted);
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        HexaBPMSRStatusList.add(approvedByFinance);
        
        insert HexaBPMSRStatusList;
        testData.put('documents', HexaBPMSRStatusList);
        // Create Service Request Document
        HexaBPM__SR_Doc__c document = new HexaBPM__SR_Doc__c();
        document.HexaBPM__Customer__c = account.Id;
        document.HexaBPM__Document_Type__c = 'Trade/Commercial License';
        document.HexaBPM__SR_Template_Doc__c = docTemp.Id;
        document.HexaBPM__Service_Request__c = serviceRequest.Id;
        document.HexaBPM__Document_Master__c = objDocMaster.id;
        document.Name = 'Trade/Commercial License';
        insert document;
        testData.put('document', document);

        // Create ContentVersion
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = 'Trade/Commercial License';
        newContentVersion.PathOnClient = '/' + newContentVersion.Title + '.pdf';
        newContentVersion.VersionData = Blob.valueOf('Sample File Data');
        insert newContentVersion;

        String contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersion.Id LIMIT 1
        ].ContentDocumentId;

        // Create ContentDocumentLink
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = contentDocumentId;
        documentLink.LinkedEntityId = document.Id;
        documentLink.ShareType = 'V';
        documentLink.Visibility = 'AllUsers';
        insert documentLink;
        testData.put('contentDocumentId', contentDocumentId);
        testData.put('contentVersion', newContentVersion);

        return testData;
    }

    // 🔹 Test Case 1: Successful Trade License Upload
    @isTest
    static void testUploadTradeLicenceDocument_Success() {
        Map<String, Object> testData = setupTestData();
        Account account = (Account) testData.get('account');
        ContentVersion contentVersion = (ContentVersion) testData.get('contentVersion');

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/uploadTradeLicenceDocument';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => account.Id,
            'fileName' => 'TradeLicence.pdf',
            'fileData' => EncodingUtil.base64Encode(contentVersion.VersionData),
            'fileExtension' => 'pdf',
            'tradeLicenceExpiryDate' => String.valueOf(System.today().addMonths(12))
        }));
        
        RestContext.request = req;
        RestContext.response = res;
        BP_UploadTradeLicenceDoc.execute();
        Test.stopTest();

        
    }

    // 🔹 Test Case 2: Missing Account ID
    @isTest
    static void testUploadTradeLicenceDocument_MissingAccountId() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'fileName' => 'TradeLicence.pdf',
            'fileData' => EncodingUtil.base64Encode(Blob.valueOf('Sample Data')),
            'fileExtension' => 'pdf',
            'tradeLicenceExpiryDate' => String.valueOf(System.today().addMonths(12))
        }));
        
        RestContext.request = req;
        RestContext.response = res;
        BP_UploadTradeLicenceDoc.execute();
        Test.stopTest();

    }

    // 🔹 Test Case 3: Invalid File Extension
    @isTest
    static void testUploadTradeLicenceDocument_InvalidFileExtension() {
        Map<String, Object> testData = setupTestData();
        Account account = (Account) testData.get('account');

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => account.Id,
            'fileName' => 'TradeLicence.exe', // Invalid extension
            'fileData' => EncodingUtil.base64Encode(Blob.valueOf('Sample Data')),
            'fileExtension' => 'exe',
            'tradeLicenceExpiryDate' => String.valueOf(System.today().addMonths(12))
        }));

        RestContext.request = req;
        RestContext.response = res;
        BP_UploadTradeLicenceDoc.execute();
        Test.stopTest();

    }

    // 🔹 Test Case 4: Approval Already in Progress
    @isTest
    static void testUploadTradeLicenceDocument_ApprovalInProgress() {
        Map<String, Object> testData = setupTestData();
        Account account = (Account) testData.get('account');

        // Simulate an approval process already in progress
        account.RegistrationExpiryDate__c = System.today().addMonths(12);
        update account;

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => account.Id,
            'fileName' => 'TradeLicence.pdf',
            'fileData' => EncodingUtil.base64Encode(Blob.valueOf('Sample Data')),
            'fileExtension' => 'pdf',
            'tradeLicenceExpiryDate' => String.valueOf(System.today().addMonths(12))
        }));

        RestContext.request = req;
        RestContext.response = res;
        BP_UploadTradeLicenceDoc.execute();
        Test.stopTest();

       
    }
   

}