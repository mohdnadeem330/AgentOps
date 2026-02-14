@isTest
private class BP_ManageAgentsTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('test agency 1', '46757869898');
        insert testAccount;
        
        // Create test Contacts
        Contact testContact1 = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', 
                                           MobilePhone = '1234567890', AccountId = testAccount.Id, 
                                           BrokerType__c = 'Agent', AgentStatus__c = 'Active',
                                           RecordTypeId = ALD_Constants.BROKER_AGENT_RT,NationalIdNumber__c = '784123456789012');

        Contact testContact2 = new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com', 
                                           MobilePhone = '0987654321', AccountId = testAccount.Id, 
                                           BrokerType__c = 'Agency Admin', AgentStatus__c = 'Pending Verification',
                                           PrimaryAgencyAdmin__c = true, RecordTypeId = ALD_Constants.BROKER_AGENT_RT , NationalIdNumber__c = '784123456789012');
        insert new List<Contact>{testContact1, testContact2};

        // Create test Users
        User testUser1 = new User(Username = 'aldar.john.doe@testBp2.com', Email = 'john.doe@test.com',
                                  LastName = 'Doe', 
                                  ContactId = testContact1.Id, IsActive = true, 
                                  LocaleSidKey = 'en_US', 
                                  LanguageLocaleKey ='en_US',
                                  Alias = 'new123', EmailEncodingKey='UTF-8', 
                                  TimeZoneSidKey='Asia/Dubai',
                                  ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1].Id);
        insert testUser1;

        // Create test Documents
        Document__c doc1 = new Document__c(DocumentType__c = 'Emirates ID Copy', Contact__c = testContact1.Id);
        insert doc1;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('AgencyRegistration');        
        insert SRTemplateDetailRecord;
        
        Id agencyTemplateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration');
        HexaBPM__SR_Status__c Approved = TestObjectsFactory.getSRStatus('Approved');
        insert Approved;
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(Approved.Id, null, 'Agency Registration', agencyTemplateId, SRTemplateDetailRecord.Id);
        newSR.HexaBPM__Customer__c = testAccount.Id;
        insert newSR;

		HexaBPM__SR_Doc__c doc2 = new HexaBPM__SR_Doc__c(HexaBPM__Service_Request__c = newSR.Id, Name = 'Trade/Commercial License', HexaBPM__Customer__c = testAccount.Id);
        insert doc2;    
        ContentVersion contentVer2 = new ContentVersion(
            Title = 'Test File', PathOnClient = 'TestFile.txt', VersionData = Blob.valueOf('This is a test file.'),IsMajorVersion = true
        );
        insert contentVer2;
        // Fetch the ContentDocument ID
        ContentDocument contentDoc2 = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVer2.Id) LIMIT 1];

        // Create ContentDocumentLink to associate it with the Account
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = doc2.Id, // Linking to Document
            ContentDocumentId = contentDoc2.Id,
            ShareType = 'V' // Viewer permission
        );
        insert cdl2;
        
        // Create ContentVersion (First insert into ContentVersion, which creates ContentDocument)
        ContentVersion contentVer = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is a test file.'),
            IsMajorVersion = true
        );
        insert contentVer;

        // Fetch the ContentDocument ID
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.Id) LIMIT 1];

        // Create ContentDocumentLink to associate it with the Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = doc1.Id, // Linking to Document
            ContentDocumentId = contentDoc.Id,
            ShareType = 'V' // Viewer permission
        );
        insert cdl;
    }
    
    @isTest
    static void testExecute_ValidRequest() {
        
        List<Account> listAcc = [SELECT Id,(SELECT Id FROM Contacts LIMIT 1) FROM Account];
        // Set up test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"agencyId": "' + listAcc[0].Id + '", "contactId": "' + listAcc[0].Contacts[0].Id + '","accountDocuments": true, "limit": 10, "offset": 0}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call method
        Test.startTest();
        BP_ManageAgents.execute();
        Test.stopTest();

        // Verify response
        //System.assertEquals(200, res.statusCode);
    }
    
    @isTest
    static void testExecute_InvalidRequest() {
        // Set up test request with an empty body
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call method
        Test.startTest();
        BP_ManageAgents.execute();
        Test.stopTest();

        // Verify response
        //System.assertEquals(500, res.statusCode);
    }
    
    @isTest
    static void testProcessRequest_ValidParams() {
        // Instantiate class
        BP_ManageAgents service = new BP_ManageAgents();

        // Prepare test data
        Map<String, String> params = new Map<String, String>();
        String requestBody = '{"agencyId": "' + [SELECT Id FROM Account LIMIT 1].Id + '", "limit": 10, "offset": 0}';

        // Call method
        Test.startTest();
        service.processRequest(params, requestBody);
        Test.stopTest();

        // Verify response
        /*System.assert(response.success);
        System.assertEquals(200, response.statusCode);
        System.assertNotEquals(null, response.data);*/
    }
    
    @isTest
    static void testGetContacts() {
        // Fetch test agency ID
        String agencyId = [SELECT Id FROM Account LIMIT 1].Id;

        // Call method
        Test.startTest();
        List<BP_ManageAgents.AgentInformation> agents = BP_ManageAgents.getContacts(agencyId, 10, 0, null, null, null, false);
        Test.stopTest();

        // Verify results
        System.assert(agents.size() > 0, 'Agents should be retrieved');
    }

    @isTest
    static void testGetTotalAgentCount() {
        // Fetch test agency ID
        String agencyId = [SELECT Id FROM Account LIMIT 1].Id;

        // Call method
        Test.startTest();
        Integer count = BP_ManageAgents.getTotalAgentCount(agencyId, null, null, null);
        Test.stopTest();

        // Verify count
        System.assert(count > 0, 'Total agent count should be greater than 0');
    }
}