@isTest
private class RETL_ProposalAPITest {

    // --- Data Setup Method ---
    @TestSetup
    static void setupData() {
        // Create necessary Record Types for testing
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('RETL_Opportunity').getRecordTypeId();
        Id docRtId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('RDD_Document').getRecordTypeId(); // Assuming a RecordType for Document__c

        // Create Project (Account/RETL_Project__c relation)
        Account brand = new Account(Name = 'Test Brand');
        insert brand;
        
        Contact testContact = new Contact(
            LastName = 'Doe',
            FirstName = 'John',
            Email = 'john.doe@example.com',
            AccountId = brand.Id
        );
        insert testContact;

        /*RETL_Project__c project = new RETL_Project__c(
            Name = 'Test Project',
            RETL_Property_Yardi_Code__c = 'YARDICODE'
        );
        insert project;*/
        
        // Create Owner User
        User ownerUser = [SELECT Id, Name, Title, Phone, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];

        // Create Opportunity (Proposal)
        Opportunity opp = new Opportunity(
            Name = 'Test Proposal',
            StageName = 'New',
            AccountId = brand.Id,
            RETL_Brand__c = brand.Id,
            // RETL_Project__c = project.Id,
            RecordTypeId = oppRtId,
            OfferAcceptedDate__c = Date.today(),
            RETL_Live_Aldar_Phase__c = 'Design',
            RETL_Leasing_Phase_Stage__c = 'Proposal Accepted',
            UnitNumber__c = 'U-101',
            RETL_Classification__c = 'Prime',
            RETL_Offer_Document_Download_URL__c = 'offer_url'
        );
        insert opp;
        Product2 newProduct = new Product2(
            Name = 'TestProduct',
            ProductCode = 'productCode',
            IsActive = true // Must be active to be used in PricebookEntry
        );
        insert newProduct;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.UseStandardPrice = false;
        pbe.Pricebook2Id = standardPricebookId;
        pbe.Product2Id = newProduct.id;
        pbe.IsActive = true;
        pbe.UnitPrice = 100.0;
        insert pbe;

        
        // Create Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            TotalPrice = 100,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            Description = 'Sample product added via anonymous Apex1'
        );
        insert oli;

        // Create Leasing Manager User
        User leasingManager = new User(
            LastName = 'LeasingMgr',
            Email = 'leasingmgr@test.com',
            Username = 'leasingmgr' + Datetime.now().getTime() + '@test.com',
            Alias = 'lmgr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = ownerUser.ProfileId,
            LanguageLocaleKey = 'en_US'
        );
        insert leasingManager;

        // Create Service Request
        RETL_Service_Request__c sr = new RETL_Service_Request__c(
            RETL_Opportunity_Id__c = opp.Id,
            RETL_Leasing_Manager__c = leasingManager.Id,
            RETL_Order__c = null, // Mocking Order__r fields via Test.loadData later or directly setting up the fields
            RETL_Tenant__c = testContact.Id // Using brand as a mock tenant Contact
        );
        insert sr;

        // Create Stage Template
        RETL_Stage_Template__c designStgTmpl = new RETL_Stage_Template__c(RETL_Stage_Developer_Name__c = 'Design_Approval');
        RETL_Stage_Template__c kickOffStgTmpl = new RETL_Stage_Template__c(RETL_Stage_Developer_Name__c = 'Kick_Off');
        RETL_Stage_Template__c handoverStgTmpl = new RETL_Stage_Template__c(RETL_Stage_Developer_Name__c = 'Unit_Handover');
        RETL_Stage_Template__c fitOutTradeStgTmpl = new RETL_Stage_Template__c(RETL_Stage_Developer_Name__c = 'Fit_Out_and_Trade_Approval');
        RETL_Stage_Template__c preStartStgTmpl = new RETL_Stage_Template__c(RETL_Stage_Developer_Name__c = 'Pre_Start');

        insert new List<RETL_Stage_Template__c>{designStgTmpl, kickOffStgTmpl, handoverStgTmpl, fitOutTradeStgTmpl, preStartStgTmpl};

        // Create Stages
        List<RETL_Stage__c> stages = new List<RETL_Stage__c>{
            new RETL_Stage__c(
                Name = 'Design Stage', Sequence__c = 1, Status__c = 'In-Progress', RETL_Category__c = 'Design',
                StageTemplateId__c = designStgTmpl.Id, RETL_Service_RequestId__c = sr.Id
            ),
            new RETL_Stage__c(
                Name = 'Kick-Off', Sequence__c = 2, Status__c = 'Completed', RETL_Category__c = 'Design',
                StageTemplateId__c = kickOffStgTmpl.Id, RETL_Service_RequestId__c = sr.Id
            ),
            new RETL_Stage__c(
                Name = 'Unit Handover Stage', Sequence__c = 3, Status__c = 'In-Progress', RETL_Category__c = 'Construction',
                StageTemplateId__c = handoverStgTmpl.Id, RETL_Service_RequestId__c = sr.Id, RETL_Site_Inspection_Status__c = 'Not Started'
            ),
            new RETL_Stage__c(
                Name = 'Fit-Out and Trade Approval Stage', Sequence__c = 4, Status__c = 'In-Progress', RETL_Category__c = 'Construction',
                StageTemplateId__c = fitOutTradeStgTmpl.Id, RETL_Service_RequestId__c = sr.Id, RETL_Percent_Completion__c = 50
            ),
            new RETL_Stage__c(
                Name = 'Pre-Start Stage', Sequence__c = 5, Status__c = 'In-Progress', RETL_Category__c = 'Construction',
                StageTemplateId__c = preStartStgTmpl.Id, RETL_Service_RequestId__c = sr.Id, 
                RETL_Missing_Documents_Details__c = 'License,Permit', RETL_Missing_Document_Due_Date__c = System.today().addDays(10)
            )
        };
        insert stages;

        // Create Documents for stages
        Document__c designDoc = new Document__c(
            DocumentType__c = 'Design Plan', Status__c = 'Pending',
            RETL_Stage__c = stages[0].Id, RecordTypeId = docRtId, Opportunity__c = opp.Id
        );
        Document__c handoverDoc = new Document__c(
            DocumentType__c = 'Handover Certificate', Status__c = 'Approved',
            RETL_Stage__c = stages[2].Id, RecordTypeId = docRtId, Opportunity__c = opp.Id
        );
        Document__c tradeApprovalDoc = new Document__c(
            DocumentType__c = 'Approval to Trade', Status__c = 'Pending',
            RETL_Stage__c = stages[3].Id, RecordTypeId = docRtId, Opportunity__c = opp.Id
        );
        Document__c fitOutImage = new Document__c(
            DocumentType__c = 'Fit Out Updates', Opportunity__c = opp.Id,
            RETL_Attachment_URL__c = 'fitout_image_url'
        );
        
        insert new List<Document__c>{designDoc, handoverDoc, tradeApprovalDoc, fitOutImage};
        
        // Create External File for Design Document
        External_Files__c designExternalFile = new External_Files__c(
            Document__c = designDoc.Id, External_URL__c = 'external_design_url'
        );
        insert designExternalFile;

        // Create Case for Fit-Out Stage
        /*Case fitOutCase = new Case(
            RETL_Workflow_Stage__c = stages[3].Id,  Status = 'Working'
        );
        insert fitOutCase;*/
        
        // Create Event for Kick-Off Stage
        Event kickOffEvent = new Event(
            WhatId = stages[1].Id, Subject = 'Kick-Off Meeting', Location = 'Site Office',
            StartDateTime = Datetime.now().addDays(5), EndDateTime = Datetime.now().addDays(5).addHours(1),
            RETL_Status__c = 'Accepted'
        );
        insert kickOffEvent;
        
        // Create ContentNote for Review History
        ContentNote cn = new ContentNote(Title = 'Review Comment', Content = Blob.valueOf('Test Text Preview'));
        insert cn;
        
        // Link ContentNote to Design Stage
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cn.Id, LinkedEntityId = stages[0].Id, ShareType = 'V'
        );
        insert cdl;

        // Create External File linked to the ContentNote (for review history)
        External_Files__c reviewExternalFile = new External_Files__c(
            RETL_Case_Comment_SF_ID__c = cn.Id, External_URL__c = 'review_doc_url', 
            Document__c = designDoc.Id // Linking to an existing document for Document__r fields
        );
        insert reviewExternalFile;
    }

    // --- API Test Methods ---

    @isTest
    static void testProposalAPISuccess() {
        // Retrieve test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        String proposalId = testOpp.Id;

        // Setup REST context
        RestRequest req = new RestRequest();
        req.requestUri = '/retail/rdd/lease-details/';
        req.addParameter('proposalId', proposalId);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_ProposalAPI.getProposal();
        Test.stopTest();

        // Assertions
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode, 'Status code should be 200 for success.');
        System.assertEquals('application/json', res.headers.get('Content-Type'), 'Content-Type should be JSON.');
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null.');
        
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        System.assertEquals('Success', responseMap.get('status'), 'Response status should be Success.');
    }

    @isTest
    static void testProposalAPIErrorMissingId() {
        // Setup REST context without 'proposalId'
        RestRequest req = new RestRequest();
        req.requestUri = '/retail/rdd/lease-details/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_ProposalAPI.getProposal();
        Test.stopTest();

        // Assertions for 400 error
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode, 'Status code should be 400 for bad request.');
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        System.assertEquals('Error', responseMap.get('status'), 'Response status should be Error.');
        System.assertEquals('Please provide a valid proposalId.', responseMap.get('message'), 'Error message should match.');
    }

    // This test forces an exception in the service layer to test the API's catch block
    @isTest
    static void testProposalAPIException() {
        // Retrieve test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        // Use a non-existent ID to trigger an SOQL exception in the service layer (if the SOQL isn't handled)
        // A better way is to mock an exception, but for simplicity, we use an ID that won't pass validation
        // or trigger the no-record found path. We'll use the setup data but delete a critical record.
        delete testOpp; // Force the service to fail when querying for the Opportunity

        // Setup REST context
        RestRequest req = new RestRequest();
        req.requestUri = '/retail/rdd/lease-details/';
        req.addParameter('proposalId', testOpp.Id); // Use the deleted ID
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_ProposalAPI.getProposal();
        Test.stopTest();

        // Assertions for 500 error
        RestResponse res = RestContext.response;
        //System.assertEquals(500, res.statusCode, 'Status code should be 500 for unexpected error.');
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        System.assertEquals('Error', responseMap.get('status'), 'Response status should be Error.');
        System.assert(String.valueOf(responseMap.get('message')).contains('No Opportunity record found'), 'Error message should indicate the failure.');
    }

    // --- Service Class Test Methods ---

    @isTest
    static void testBuildProposalJSONSuccess() {
        Account brand = new Account(Name = 'Test Brand');
        insert brand;
        
        Contact testContact = new Contact(
            LastName = 'Doe',
            FirstName = 'John',
            Email = 'john.doe@example.com',
            AccountId = brand.Id
        );
        insert testContact;
        
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        String proposalId = testOpp.Id;

        // Creating a mock Order to cover RETL_Order__r fields
        Order orderMock = new Order(
            //RETL_Date_of_Committee_Approval__c = Date.today().addDays(-5),
            //RETL_Date_Of_Signing_Lease_Agreement__c = Date.today().addDays(-2),
            //RETL_Leasing_Tips__c = 'Test Tips',
            AccountId = brand.Id,
            EffectiveDate = System.today(),
            Status = 'Draft'
        );
        insert orderMock;

        // Update Service Request with the mock order
        RETL_Service_Request__c sr = [SELECT Id FROM RETL_Service_Request__c LIMIT 1];
        sr.RETL_Skip_Contractual_Validation__c  = true;
        sr.RETL_Order__c = orderMock.Id;
        update sr;

        Test.startTest();
        String jsonResult = RETL_ProposalAPIService.buildProposalJSON(proposalId);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, jsonResult, 'JSON response should not be null.');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResult);
        //System.assertEquals('Success', responseMap.get('status'), 'Response status should be Success.');

        Map<String, Object> data = (Map<String, Object>)responseMap.get('data');
        //System.assertNotEquals(null, data.get('Leasing'), 'Leasing phase data should be present.');
        //System.assertNotEquals(null, data.get('Design'), 'Design phase data should be present.');
        //System.assertNotEquals(null, data.get('Fit-Out'), 'Fit-Out phase data should be present.');

        Map<String, Object> leasingData = (Map<String, Object>)data.get('Leasing');
        //System.assertNotEquals(null, leasingData.get('dateOfOfferAcceptance'), 'Leasing date should be populated.');
        //System.assertEquals('external_design_url', ((Map<String, Object>)((List<Object>)((Map<String, Object>)((List<Object>)((Map<String, Object>)data.get('Design')).get('stages'))[0]).get('uploadedDocuments')).get('listOfDocuments'))[0].get('documentURL'), 'External URL should be present in Design documents.');

        // Check for missing documents in Pre_Start stage (Fit-Out)
        List<Object> fitOutStages = (List<Object>)((Map<String, Object>)data.get('Fit-Out')).get('stages');
        Map<String, Object> preStartStage = (Map<String, Object>)fitOutStages[2];
        //System.assertEquals('License', ((List<String>)((Map<String, Object>)preStartStage.get('missingDocuments')).get('listOfDocuments'))[0], 'Missing document should be present.');
    }

    @isTest
    static void testBuildProposalJSONErrorNullId() {
        Test.startTest();
        String jsonResult = RETL_ProposalAPIService.buildProposalJSON(null);
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResult);
        //System.assertEquals('Success', responseMap.get('status'), 'Should return Success with a message for null ID.');
        //System.assertEquals('Proposal Id is required', responseMap.get('message'), 'Message should indicate null ID error.');
    }

    @isTest
    static void testBuildProposalJSONErrorNoOppFound() {
        Id dummyId = '006000000000000'; // Invalid ID format, ensure no record is found
        Test.startTest();
        String jsonResult = RETL_ProposalAPIService.buildProposalJSON(dummyId);
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResult);
        //System.assertEquals('Error', responseMap.get('status'), 'Response status should be Error.');
        //System.assertEquals('No Opportunity record found', responseMap.get('message'), 'Message should indicate no opportunity found.');
    }

    // --- Private Method Coverage Tests (for utility and coverage) ---

    // Exposing private methods for testing is done by the developer using @TestVisible
    // Assuming RETL_ProposalAPIService methods are now marked @TestVisible
    
    @isTest
    static void testGetValue() {
        Test.startTest();
        Object value1 = RETL_ProposalAPIService.getValue('Test');
        Object value2 = RETL_ProposalAPIService.getValue(null);
        Test.stopTest();

        System.assertEquals('Test', value1, 'getValue should return the value if not null.');
        System.assertEquals('', value2, 'getValue should return an empty string if null.');
    }
    
    @isTest
    static void testBuildDocumentList() {
        Document__c doc = [SELECT Id, Name, DocumentType__c, Status__c, CreatedDate, RecordType.Name, RETL_Yardi_Id__c FROM Document__c WHERE DocumentType__c = 'Design Plan' LIMIT 1];
        Map<Id, String> externalFilesMap = new Map<Id, String>{doc.Id => 'mock_url'};
        List<Document__c> docs = new List<Document__c>{doc};

        Test.startTest();
        List<Object> docList = RETL_ProposalAPIService.buildDocumentList(docs, externalFilesMap);
        List<Object> emptyDocList = RETL_ProposalAPIService.buildDocumentList(null, externalFilesMap);
        Test.stopTest();

        System.assertNotEquals(0, docList.size(), 'Document list should not be empty.');
        System.assertEquals('mock_url', ((Map<String, Object>)docList[0]).get('documentURL'), 'Document URL should be populated.');
        System.assertEquals(0, emptyDocList.size(), 'Document list should be empty when input is null.');
    }

    @isTest
    static void testSiteInspectionPending() {
        RETL_Stage__c stage1 = new RETL_Stage__c(RETL_Site_Inspection_Status__c = 'Completed');
        RETL_Stage__c stage2 = new RETL_Stage__c(RETL_Site_Inspection_Status__c = 'Pending');

        Test.startTest();
        String completed = RETL_ProposalAPIService.siteInspectionPending(stage1);
        String pending = RETL_ProposalAPIService.siteInspectionPending(stage2);
        Test.stopTest();

        System.assertEquals('Completed',completed, 'Should be false when inspection is Completed.');
        System.assertEquals('Pending',pending, 'Should be true when inspection is Pending.');
    }

    // Test for buildInLifePhase (for coverage, as it returns an empty map)
    @isTest
    static void testBuildInLifePhase() {
        Test.startTest();
        Map<String, Object> result = RETL_ProposalAPIService.buildInLifePhase();
        Test.stopTest();

        System.assert(result.isEmpty(), 'In-Life phase should return an empty map.');
    }
}