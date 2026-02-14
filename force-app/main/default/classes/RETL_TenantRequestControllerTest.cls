/**
* @File Name : RETL_TenantRequestControllerTest.cls
* Apex Controller : RETL_TenantRequestController
* @Description : Unit Tests for RETL_TenantRequestController
* @Author : Kumar Gaurav (Protiviti)
* @Last Modified By : Kumar Gaurav
* @Last Modified On : September 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 24, 2025 | Kumar Gaurav (Protiviti) | Initial Refactor to separate methods
**/
@isTest
public class RETL_TenantRequestControllerTest {
    
    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Tenant', ECSS_Trade_License_Number__c = 'TL1234');
        insert acc;
        
        // Create Contact
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id, Email='test@test.com');
        insert con;
        
        // Create Order (Lease)
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RETL_Property_Name__c = 'Test Mall',
            RETL_Status__c = 'Current'
        );
        insert ord;
        
        // Create Entitlement
        Entitlement ent = new Entitlement(Name='Test Entitlement', AccountId=acc.Id);
        ent.RETL_SR_Category__c = 'NOC';
        ent.RETL_SR_Sub_Category__c = 'Police';
        ent.RETL_SR_Service_Type__c = 'Overnight Works';
        insert ent;
        
        // RETL_SR_Master__c
        RETL_SR_Master__c master = new RETL_SR_Master__c(
            Name='NocMaster1',
            RETL_Category__c = 'NOC',
            RETL_Sub_Category__c = 'Police',
            RETL_Service_Type__c = 'Overnight Works',
            RETL_Active__c=true
        );
        insert master;
        
        // Section + Field Mapping
        RETL_SR_Section__c section = new RETL_SR_Section__c(
            Name='Section1',
            RETL_SR_Master__c = master.Id,
            RETL_Step_Title__c='Step1',
            RETL_Display_Order__c=1
        );
        insert section;
        
        RETL_SR_Field_Mapping__c fm = new RETL_SR_Field_Mapping__c(
            Name = 'FM1',
            RETL_SR_Section__c = section.Id,
            RETL_Form_Field_Name__c = 'Test Field',
            RETL_SF_Field_Name__c = 'CaseNumber',
            RETL_SF_Object_Name__c = 'Case',
            RETL_Data_Type__c = 'Text',
            RETL_Display_Order__c = 1,
            RETL_Required__c = true
        );
        insert fm;
        
        // Create a Case for tests
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            ContactId = con.Id,
            RETL_SR_Category__c = 'Category A',
            RETL_SR_Sub_Category__c = 'SubCat A',
            RETL_SR_Service_Type__c = 'Service A'
        );
        insert c;

        List<Group> existingQueues = [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE DeveloperName = 'Retail_SR_Queue' AND Type = 'Queue'
            LIMIT 1
        ];
        
        Group g;
        if (existingQueues.isEmpty()) {
            g = new Group(
                DeveloperName = 'Retail_SR_Queue',
                Name = 'Retail SR Queue',
                Type = 'Queue'
            );
            insert g;
        } else {
            g = existingQueues[0];
        }
    }
    
    @isTest
    static void testGetCaseComment() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        insert new CaseComment(
            ParentId   = testCase.Id,
            CommentBody = 'Test Comment',
            IsPublished = true
        );
        // prepare inputs
        Map<String, Object> sectionFieldMap = new Map<String, Object>();
        List<retl_TenantRequestController.ExternalFileWrapper> files = 
            new List<retl_TenantRequestController.ExternalFileWrapper>();
        
        Test.startTest();
        List<Map<String,Object>> result = retl_TenantRequestController.getCaseComment(
            String.valueOf(testCase.Id),
            sectionFieldMap,
            files
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return history list');
        System.assert(result.size() > 0, 'History list should contain at least 1 entry');
        System.assertEquals('Test Comment', (String)result[0].get('comment'));
    }
    
    @IsTest
    static void testGetCaseDocumentsAndComments() {
        // Create Account and Contact
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName='Test', LastName='User', AccountId=acc.Id);
        insert con;
        
        // Create Case
        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin = 'Customer App',
            Status = 'New',
            Vertical__c='Aldar Retail',
            SubVertical__c='Retail',
            RETL_SR_Category__c='NOC',
            RETL_SR_Sub_Category__c='Police',
            RETL_SR_Service_Type__c='Overnight Works',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert c;
        
        // Mock ExternalFileWrapper data by inserting custom objects or mocking getDocuments
        // Since getDocuments is private/static, use Test.isRunningTest() block in controller
        Test.startTest();
        Map<String, List<retl_TenantRequestController.ExternalFileWrapper>> docMap = 
            retl_TenantRequestController.getCaseDocuments(c.Id, 'NOC');
        List<Map<String, Object>> commentHistory = 
            retl_TenantRequestController.getCaseCommentHistory(c.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, docMap, 'Document map should not be null');
        System.assertNotEquals(null, commentHistory, 'Comment history should not be null');
    }
    @IsTest
    static void testSaveCaseComment_Success() {
        // Create Account and Contact
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName='Test', LastName='User', AccountId=acc.Id);
        insert con;
        // Create Case
        Case testCase = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin = 'Customer App',
            Status = 'New',
            Vertical__c='Aldar Retail',
            SubVertical__c='Retail',
            RETL_SR_Category__c='NOC',
            RETL_SR_Sub_Category__c='Police',
            RETL_SR_Service_Type__c='Overnight Works',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert testCase;
        
        // Step 2: Define a sample comment
        String sampleComment = 'This is a test case comment.';
        
        // Step 3: Call the method under test
        Test.startTest();
        Map<String, Object> result = retl_TenantRequestController.saveCaseComment(testCase.Id, sampleComment);
        
        
        // Step 4: Assert results
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('Id'), 'Result should contain Id');
        System.assertEquals(testCase.Id, (Id) result.get('ParentId'), 'ParentId should match Case Id');
        System.assertEquals(sampleComment, (String) result.get('CommentBody'), 'CommentBody should match input comment');
        
        // Step 5: Validate database record
        List<CaseComment> createdComments = [
            SELECT Id, ParentId, CommentBody, IsPublished 
            FROM CaseComment 
            WHERE ParentId = :testCase.Id
        ];
        Test.stopTest();
        System.assertEquals(1, createdComments.size(), 'One CaseComment should have been created');
        System.assertEquals(true, createdComments[0].IsPublished, 'Case comment should be published');
        System.assertEquals(sampleComment, createdComments[0].CommentBody, 'CommentBody should match expected text');
    }
    
    @IsTest
    static void testSaveCaseComment_BlankComment() {
        // Create Account and Contact
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName='Test', LastName='User', AccountId=acc.Id);
        insert con;
        // Create Case
        Case testCase = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin = 'Customer App',
            Status = 'New',
            Vertical__c='Aldar Retail',
            SubVertical__c='Retail',
            RETL_SR_Category__c='NOC',
            RETL_SR_Sub_Category__c='Police',
            RETL_SR_Service_Type__c='Overnight Works',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert testCase;
        
        // Step 2: Call method with blank comment
        Test.startTest();
        Map<String, Object> result = retl_TenantRequestController.saveCaseComment(testCase.Id, '');
        
        
        // Step 3: Verify that no CaseComment was created
        System.assertEquals(true, result.isEmpty(), 'Result should be empty for blank comment');
        
        Integer commentCount = [SELECT COUNT() FROM CaseComment WHERE ParentId = :testCase.Id];
        
        Test.stopTest();
        System.assertEquals(0, commentCount, 'No case comment should be created when comment is blank');
    }
    
    
    @IsTest
    static void testGetCaseDetails_FullFlow() {
        
        // Step 1: Create Account, Contact, Case base data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id);
        insert con;
        
        // Step 2: Create Master and Section records
        RETL_SR_Master__c master = new RETL_SR_Master__c(
            Name = 'NOC - Police - Overnight Works',
            RETL_Category__c = 'NOC',
            RETL_Sub_Category__c = 'Police',
            RETL_Service_Type__c = 'Overnight Works'
        );
        insert master;
        
        RETL_SR_Section__c sectionService = new RETL_SR_Section__c(
            Name = 'Service Info Section',
            RETL_SR_Master__c = master.Id,
            RETL_SR_Section_Title__c = 'Application Fields',
            RETL_Accordion_Name__c = 'Service Information',
            RETL_Confirmation_And_My_Request__c = true,
            RETL_Display_Order__c = 1,
            RETL_Visible__c = true
        );
        insert sectionService;
        
        RETL_SR_Section__c sectionContractor = new RETL_SR_Section__c(
            Name = 'Contractor Section',
            RETL_SR_Master__c = master.Id,
            RETL_SR_Section_Title__c = 'Contractor Fields',
            RETL_Accordion_Name__c = 'Contractor Details',
            RETL_Confirmation_And_My_Request__c = true,
            RETL_Display_Order__c = 2,
            RETL_Visible__c = true
        );
        insert sectionContractor;
        
        
        
        // Step 4: Create Field Mappings under both sections
        RETL_SR_Field_Mapping__c fm1 = new RETL_SR_Field_Mapping__c(
            Name = 'Trading Name Field',
            RETL_Form_Field_Name__c = 'Trading Name (Arabic)',
            RETL_Data_Type__c = 'Text',
            RETL_SF_Field_Name__c = 'RETL_Trading_Name__c',
            RETL_SF_Object_Name__c = 'RETL_SR_Additional_Info__c',
            RETL_SR_Section__c = sectionService.Id,
            RETL_Display_Order__c = 1
        );
        insert fm1;
        
        RETL_SR_Field_Mapping__c fm2 = new RETL_SR_Field_Mapping__c(
            Name = 'Contractor Email Field',
            RETL_Form_Field_Name__c = 'Email Address',
            RETL_Data_Type__c = 'Email',
            RETL_SF_Field_Name__c = 'RETL_Contractor__r.EmailAddress__c',
            RETL_SF_Object_Name__c = 'Account',
            RETL_SR_Section__c = sectionContractor.Id,
            RETL_Display_Order__c = 1
        );
        insert fm2;
        
        Test.startTest();
        
        // Step 5: Create Case record linked to Additional Info
        Case testCase = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin = 'Customer App',
            Status = 'New',
            RETL_SR_Category__c = 'NOC',
            RETL_SR_Sub_Category__c = 'Police',
            RETL_SR_Service_Type__c = 'Overnight Works',
            // RETL_SR_Additional_Info__c = addInfo.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert testCase;
        // Step 3: Create Additional Info record
        RETL_SR_Additional_Info__c addInfo = new RETL_SR_Additional_Info__c(
            RETL_Case__c=testCase.id,
            RETL_Unit_No__c = 'U123',
            RETL_Trading_Name__c = 'Test Trading Name'
        );
        insert addInfo;

        testCase.RETL_SR_Additional_Info__c = addInfo.Id;
        update testCase;
        // Step 6: Create Contractor and linkage
        Account contractor = new Account(Name = 'ABC Contractor', Email__c = 'abc@contractor.com');
        insert contractor;
        
        RETL_Contractor_Case_Linkage__c linkage = new RETL_Contractor_Case_Linkage__c(
            RETL_Case__c = testCase.Id,
            RETL_Contractor__c = contractor.Id
        );
        insert linkage;
        
        // Step 7: Create CaseComment (to support includeComments flag)
        CaseComment cmt = new CaseComment(ParentId = testCase.Id, CommentBody = 'This is a test comment', IsPublished = true);
        insert cmt;
        
        Map<String, Object> result = retl_TenantRequestController.getCaseDetails(
            testCase.Id,
            true,  // includeDocuments
            true,  // includeComments
            true   // includeAccordions
        );
        Test.stopTest();
        
        // Step 8: Validate Results
        System.assertNotEquals(null, result, 'Returned map should not be null');
        System.assert(result.containsKey('case'), 'Case details should exist');
        System.assert(result.containsKey('comments'), 'Comments should exist when includeComments is true');
        //System.assert(result.containsKey('accordions'), 'Accordions should exist when includeAccordions is true');
        
        //List<Map<String, Object>> accordions = (List<Map<String, Object>>) result.get('accordions');
        //System.assert(!accordions.isEmpty(), 'Accordions should not be empty');
        //System.assertEquals('Service Information', accordions[0].get('title'), 'Accordion title should match');
    }
    @IsTest
    private static void testGetDocuments() {
        // Step 1: Create a Case
        Case c = new Case(
            Origin = 'Customer App',
            Status = 'New',
            Subject = 'Test subject here',
            
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert c;
        
        // Step 2: Create Document__c records linked to the Case
        Document__c doc1 = new Document__c(
            Case__c = c.Id,
            DocumentType__c = 'NOC'
        );
        Document__c doc2 = new Document__c(
            Case__c = c.Id,
            DocumentType__c = 'Attachment Document'
        );
        insert new List<Document__c>{ doc1, doc2 };
            
            // Step 3: Create External_Files__c records for each document
            External_Files__c ext1 = new External_Files__c(
                Document__c = doc1.Id,
                File_Name__c = 'NOCFile.pdf',
                External_URL__c = 'https://example.com/noc',
                RETL_Case_Comment_SF_ID__c = '500xx0000012345AAA'
            );
        External_Files__c ext2 = new External_Files__c(
            Document__c = doc2.Id,
            File_Name__c = 'Attachment1.pdf',
            External_URL__c = 'https://example.com/attachment'
        );
        insert new List<External_Files__c>{ ext1, ext2 };
            
            // Step 4: Call the method
            Test.startTest();
        Map<String, List<retl_TenantRequestController.ExternalFileWrapper>> result =
            retl_TenantRequestController.getDocuments(c.Id);
        Test.stopTest();
        
        // Step 5: Validate the results
        System.assertNotEquals(0, result.size(), 'Result map should not be empty');
        System.assert(result.containsKey('NOC'), 'Map should contain NOC key');
        System.assert(result.containsKey('Attachment Document'), 'Map should contain Attachment Document key');
        
        // Validate NOC file
        List<retl_TenantRequestController.ExternalFileWrapper> nocFiles = result.get('NOC');
        System.assertEquals(1, nocFiles.size(), 'NOC should have one file');
        System.assertEquals('NOCFile.pdf', nocFiles[0].fileName, 'File name should match');
        System.assertEquals('https://example.com/noc', nocFiles[0].fileLink, 'File link should match');
        System.assertEquals('500xx0000012345AAA', nocFiles[0].caseCommentSFId, 'Case comment ID should match');
        
        // Validate Attachment Document
        List<retl_TenantRequestController.ExternalFileWrapper> attachFiles = result.get('Attachment Document');
        System.assertEquals(1, attachFiles.size(), 'Attachment Document should have one file');
        System.assertEquals('Attachment1.pdf', attachFiles[0].fileName, 'Attachment file name should match');
        System.assertEquals('https://example.com/attachment', attachFiles[0].fileLink, 'Attachment link should match');
    }
    
    @isTest static void testGetMyRequests() {
        Test.startTest();
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Contact con = new Contact(LastName='Tester', AccountId=acc.Id);
        insert con;
        
        RETL_Contact_Role__c role = new RETL_Contact_Role__c(
            RETL_Contact__c = con.Id,
            RETL_Account_Name__c = acc.Id,
            RETL_Contact_role__c = 'Admin'
        );
        insert role;
        
        Case c = new Case(
            ContactId = con.Id,
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Phone',
            RETL_SR_Category__c = 'NOC',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert c;
        Profile p = [SELECT Id FROM Profile WHERE Name ='Retail Contractor Profile' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = con.Id,
            Username = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;
        System.runAs(testUser) {
            
            List<Case> cases = RETL_TenantRequestController.getMyRequests(con.Id);
            
            System.assertNotEquals(0, cases.size());
        }
        Test.stopTest();  
    }
    
    @isTest static void testGetMyRequestsWithoutContact() {
        Test.startTest();
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Contact con = new Contact(LastName='Tester', AccountId=acc.Id);
        insert con;
        
        RETL_Contact_Role__c role = new RETL_Contact_Role__c(
            RETL_Contact__c = con.Id,
            RETL_Account_Name__c = acc.Id,
            RETL_Contact_role__c = 'Admin'
        );
        insert role;
        
        Case c = new Case(
            ContactId = con.Id,
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Phone',
            RETL_SR_Category__c = 'NOC',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert c;
        Profile p = [SELECT Id FROM Profile WHERE Name ='Retail Contractor Profile' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = con.Id,
            Username = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;
        System.runAs(testUser) {
            
            List<Case> cases = RETL_TenantRequestController.getMyRequests(null);
            
            System.assertNotEquals(0, cases.size());
        }
        Test.stopTest();  
    }
    
    @isTest
    static void testBuildContractorAccordionAndGetFieldValue() {
        // ===== Setup Contractor Account =====
        Account contractor = new Account(
            Name = 'ABC Contractors',
            Phone = '9876543210'
        );
        insert contractor;
        
        // ===== Setup Case =====
        Case c = new Case(
            Subject = 'Test Contractor Case',
            Status = 'New',
            Origin = 'Phone',
            RETL_SR_Category__c = 'NOC',
            RETL_SR_Sub_Category__c = 'Police',
            RETL_SR_Service_Type__c = 'Overnight Works',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
        );
        insert c;
        
        // ===== Setup Contractor Case Linkage =====
        RETL_Contractor_Case_Linkage__c linkage = new RETL_Contractor_Case_Linkage__c(
            
            RETL_Contractor__c = contractor.Id,
            RETL_Case__c = c.Id
        );
        insert linkage;
        RETL_SR_Master__c master = new RETL_SR_Master__c(
            Name = 'NOC - Police - Overnight Works',
            RETL_Category__c = 'NOC',
            RETL_Sub_Category__c = 'Police',
            RETL_Service_Type__c = 'Overnight Works'
        );
        insert master;
        // ===== Setup SR Section =====
        RETL_SR_Section__c section = new RETL_SR_Section__c(
            Name = 'Section 1',
            RETL_Accordion_Name__c = 'Contractor Details',
            RETL_Display_Order__c = 1,
            RETL_Step_Number__c = 1,
            RETL_Step_Title__c = 'Step 1',
            RETL_SR_Section_Title__c = 'Contractor Details Section',
            RETL_Visible__c = true,
            RETL_SR_Master__C=master.id
        );
        insert section;
        
        // ===== Setup Field Mappings =====
        List<RETL_SR_Field_Mapping__c> mappings = new List<RETL_SR_Field_Mapping__c>{
            new RETL_SR_Field_Mapping__c(
                RETL_Form_Field_Name__c = 'Contractor Name',
                RETL_SF_Field_Name__c = 'Name',
                RETL_SF_Object_Name__c = 'Account',
                RETL_Data_Type__c = 'Text',
                RETL_SR_Section__c = section.Id
            ),
            new RETL_SR_Field_Mapping__c(
                RETL_Form_Field_Name__c = 'Contractor Phone',
                RETL_SF_Field_Name__c = 'RETL_Contractor__r.Phone',
                RETL_SF_Object_Name__c = 'RETL_Contractor_Case_Linkage__c',
                RETL_Data_Type__c = 'Text',
                RETL_SR_Section__c = section.Id
            ),
            new RETL_SR_Field_Mapping__c(
                RETL_Form_Field_Name__c = 'Invalid Field',
                RETL_SF_Field_Name__c = 'Invalid.Relation',
                RETL_SF_Object_Name__c = 'RETL_Contractor_Case_Linkage__c',
                RETL_Data_Type__c = 'Text',
                RETL_SR_Section__c = section.Id
            )
        };
        insert mappings;
        
        // Query section with its mappings relationship
        section = [
            SELECT Id, RETL_Accordion_Name__c,
            (SELECT Id, RETL_Form_Field_Name__c, RETL_SF_Field_Name__c,
             RETL_SF_Object_Name__c, RETL_Data_Type__c
             FROM SR_Field_Mappings__r)
            FROM RETL_SR_Section__c
            WHERE Id = :section.Id
        ];
        
        // ===== Call buildContractorAccordion =====
        Test.startTest();
        Map<String, List<RETL_TenantRequestController.ExternalFileWrapper>> documentsMap = RETL_TenantRequestController.getCaseDocuments(c.Id, c.RETL_SR_Category__c);
        List<Map<String, Object>> result = RETL_TenantRequestController.buildContractorAccordion(
            c,
            new List<RETL_SR_Section__c>{ section },
            documentsMap
        );
        
        System.assertNotEquals(0, result.size(), 'Result should not be empty');
        System.assert(result[0].containsKey('fields'), 'Each section must contain fields');
        
        // ===== Direct test for getFieldValue =====
        RETL_SR_Field_Mapping__c fm = new RETL_SR_Field_Mapping__c(
            RETL_SF_Field_Name__c = 'Name',
            RETL_SF_Object_Name__c = 'Account'
        );
        String value = RETL_TenantRequestController.getFieldValue(fm, contractor);
        System.assertEquals('ABC Contractors', value, 'Should fetch contractor name correctly');
        
        // Invalid mapping test
        RETL_SR_Field_Mapping__c fmInvalid = new RETL_SR_Field_Mapping__c(
            RETL_SF_Field_Name__c = 'Invalid.Relation',
            RETL_SF_Object_Name__c = 'Account'
        );
        String invalidVal = RETL_TenantRequestController.getFieldValue(fmInvalid, contractor);
        System.assertEquals('', invalidVal, 'Should return blank for invalid relation');
        Test.stopTest();
    }
    
}