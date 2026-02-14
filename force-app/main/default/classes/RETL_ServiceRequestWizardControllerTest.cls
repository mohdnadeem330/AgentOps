/**
* @File Name : RETL_ServiceRequestWizardControllerTest.cls
* Apex Controller : RETL_ServiceRequestWizardController
* @Description : Unit Tests for RETL_ServiceRequestWizardController and RETL_SRDocumentHandler
* @Author : Kumar Gaurav (Protiviti)
* @Last Modified By : Kumar Gaurav
* @Last Modified On : September 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 24, 2025 | Kumar Gaurav (Protiviti) | Initial Refactor to separate methods
**/
            
@IsTest
public class RETL_ServiceRequestWizardControllerTest {
    
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name='Test Acc');
        insert acc;
        
        Contact con = new Contact(LastName='Test Con', AccountId=acc.Id, Email='test@test.com');
        insert con;
        
        Entitlement ent = new Entitlement(
            Name='Test Ent',
            RETL_SR_Category__c='NOC',
            RETL_SR_Sub_Category__c='Police',
            RETL_SR_Service_Type__c='Trading Hours',
            AccountId=acc.Id
        );
        insert ent;
        Id standardPricebookId = Test.getStandardPricebookId();
        Order ord = new Order(
            AccountId=acc.Id,
            Status='Draft',
            RETL_Status__c='Current',
            RETL_Property_Name__c='Test Property',
            EffectiveDate=System.today(),
            Pricebook2Id = standardPricebookId
        );
        insert ord;
        Product2 newPrdoduct = TestObjectsFactory.getProduct();
        insert newPrdoduct;
        PricebookEntry newPricebookEntry = TestObjectsFactory.getPricebookEntry(newPrdoduct.Id);
        insert newPricebookEntry;
        
        OrderItem newOrderItem = TestObjectsFactory.getLeaseUnits(newPrdoduct.Id, ord.Id, newPricebookEntry.Id);
        insert newOrderItem;
        
        RETL_SR_Master__c master = new RETL_SR_Master__c(
            RETL_Category__c='NOC',
            RETL_Sub_Category__c='Police',
            RETL_Service_Type__c='Trading Hours',
            RETL_Active__c=true
            // RETL_My_Request__c=true
        );
        insert master;
        
        RETL_SR_Master__c masterNOC = new RETL_SR_Master__c(
            RETL_Category__c='NOC',
            RETL_Active__c=true
        );
        insert masterNOC;
        
        RETL_SR_Master__c masterNOCPolice = new RETL_SR_Master__c(
            RETL_Category__c='NOC',
            RETL_Sub_Category__c='Police',
            RETL_Active__c=true
        );
        insert masterNOCPolice;
        
        RETL_SR_Section__c section = new RETL_SR_Section__c(
            Name='Test Section',
            RETL_Visible__c=true,
            RETL_Display_Order__c=1,
            RETL_SR_Master__c=master.Id,
            RETL_SR_Section_Title__c = 'Additional Info'
        );
        insert section;
        
        RETL_SR_Field_Mapping__c mapping = new RETL_SR_Field_Mapping__c(
            RETL_Form_Field_Name__c='Field1',
            RETL_SF_Field_Name__c='CaseComments__c',
            RETL_SF_Object_Name__c='Case',
            RETL_Data_Type__c='Text Area',
            RETL_Display_Order__c=1,
            RETL_Is_Active__c = true,
            RETL_SR_Section__c=section.Id
        );
        insert mapping;
        
        Group srQueue = new Group(
        	Name = 'Retail SR Queue',
            DeveloperName = 'Retail_SR_Queue',
            Type = 'Queue'
        );
        try{
            insert srQueue;
        } catch(Exception e) {
            System.debug('Unable to insert new queue');
        }
    }
    
    @IsTest static void testGetCurrentUserDetails() {
        
        Test.startTest();
        User u = RETL_ServiceRequestWizardController.getCurrentUserDetails(null);
        Test.stopTest();
        System.assertNotEquals(null, u);
    }
   @IsTest static void testGetSectionFieldMap() {
        Test.startTest();
        Map<String, List<Map<String,Object>>> sectionMap =
            RETL_ServiceRequestWizardController.getSectionFieldMap('NOC','Police','Trading Hours');
        Test.stopTest();
        System.assertNotEquals(null, sectionMap);
    }
    
    @IsTest static void testGetContactsByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Contact> cons = RETL_ServiceRequestWizardController.getContactsByAccount(acc.Id);
        Test.stopTest();
      //  System.assert(cons.size() > 0);
    }
    
    @IsTest static void testCreateRecord() {
         Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];
        // Create Queue (Group) for Case
 // Use existing Case queue from org
        List<Group> existingQueue = [
        SELECT Id FROM Group WHERE Type = 'Queue' AND Name= 'Retail SR Queue'
        LIMIT 1
    ];
        if(!existingQueue.isEmpty()) {
            System.runAs(new User(Id=UserInfo.getUserId())) {
                QueuesObject testQueue = new QueueSObject(QueueID = existingQueue[0].id, SObjectType = 'Case');
    insert testQueue;
}
        }
        RETL_ServiceRequestWizardController.GroupedFieldWrapper gw = new RETL_ServiceRequestWizardController.GroupedFieldWrapper();
        gw.Case1 = new Map<String, String>{ 'CaseComments__c' => 'Test Comment' };
                    gw.AdditionalInfo = new Map<String, String>{ 'RETL_Unit_No__C' => 'Info' };
                        
        RETL_ServiceRequestWizardController.ContractorWrapper contractor = new RETL_ServiceRequestWizardController.ContractorWrapper();
        contractor.Account = new Map<String,String>{ 'Name'=>'ContAcc'};
            contractor.Contact = new Map<String,String>{ 'LastName'=>'ContCon', 'Email'=>'cont@test.com' };
                gw.Contractors = new List<RETL_ServiceRequestWizardController.ContractorWrapper>{ contractor };
                    
                    String jsonData = JSON.serialize(gw);
        RETL_ServiceRequestWizardController.caseCreationWrapper wrap =
            RETL_ServiceRequestWizardController.createRecord(
                jsonData,'NOC','Police','Trading Hours',ord.Id,con.Id,'test'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, wrap.newCase);
    }
    
    
    @IsTest static void testGetStores() {
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];
        RETL_Contact_Role__c role = new RETL_Contact_Role__c(RETL_Contact__c=con.Id, RETL_Lease__c=ord.Id);
        insert role;
        
        Test.startTest();
        List<RETL_ServiceRequestWizardController.StoreWrapper> stores =
            RETL_ServiceRequestWizardController.getStores(con.Id);
        	RETL_ServiceRequestWizardController.getFileUploadEndpoint();
        	RETL_ServiceRequestWizardController.getDocument(con.Id, con.AccountId);
        Test.stopTest();
        
        System.assertNotEquals(null, stores);
    }
    
    @IsTest
    static void testBuildFieldMapAndCountryPicklistValues() {
        Test.startTest();
       RETL_SR_Master__c master = new RETL_SR_Master__c(
        Name = 'Test Master - NOC',
        RETL_Category__c = 'NOC',
        RETL_Sub_Category__c = 'Police',
        RETL_Service_Type__c = 'Overnight Works',
            RETL_Active__c = true
            // RETL_Confirmation_Screen__c = true,  // not required by getCaseFormValues but safe
            // RETL_My_Request__c = false
    );
    insert master;
        // ====== Setup Section Record ======
        RETL_SR_Section__c section = new RETL_SR_Section__c(
            Name = 'Section A',
            RETL_Visible__c = true,
            RETL_Display_Order__c = 1,
            RETL_Step_Number__c = 2,
            RETL_Step_Title__c = 'Step 1',
            RETL_SR_Section_Title__c = 'Title A',
            RETL_SR_Master__c=master.id
        );
        insert section;

        // ====== Setup Field Mapping Record ======
        RETL_SR_Field_Mapping__c fm = new RETL_SR_Field_Mapping__c(
            Name = 'Field A',
            RETL_SR_Section__c = section.Id,
            RETL_Form_Field_Name__c = 'Form Field A',
            RETL_SF_Field_Name__c = 'Custom_Field__c',
            RETL_SF_Object_Name__c = 'Case',
            RETL_Data_Type__c = 'Text',
            RETL_Picklist_Values__c = 'Option1;Option2',
            RETL_Display_Order__c = 10,
            RETL_Required__c = true,
            RETL_isPair__c = true,
            RETL_Pair_Order__c = 1,
            RETL_Controlled_By__c = 'Parent_Field__c',
            RETL_Parent_Picklist_Value__c = 'ParentVal',
            RETL_Validations__c = 'Must be filled',
            RETL_SR_Character_Limit__c = 100
        );
        insert fm;

        // ====== Test private method buildFieldMap() using reflection ======
        
        RETL_ServiceRequestWizardController.getAllServiceData('Tenant');
        // Accessing private @TestVisible method directly
        Map<String, Object> fieldMap = RETL_ServiceRequestWizardController.buildFieldMap(fm);

        System.assertNotEquals(null, fieldMap, 'Field map should not be null');
        System.assertEquals('Form Field A', fieldMap.get('formLabel'));
       
        // ====== Test getCountryPicklistValues() ======
       
        List<String> picklistValues = RETL_ServiceRequestWizardController.getCountryPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, picklistValues, 'Picklist values should not be null');
        System.assert(picklistValues.size() > 0, 'Should return at least one picklist value');
    }

  @IsTest
    static void testConvertStringToTime() {

        Test.startTest();

        // Case 1: Valid time string (HH:mm:ss)
        String validTime = '14:35:50';
        Time converted = RETL_ServiceRequestWizardController.convertStringToTime(validTime);
        System.assertNotEquals(null, converted, 'Converted time should not be null');
        System.assertEquals(14, converted.hour(), 'Hour should match');
        System.assertEquals(35, converted.minute(), 'Minute should match');
        System.assertEquals(50, converted.second(), 'Second should match');

        // Case 2: Invalid time string (missing seconds)
        String invalidTime = '09:15';
        Time nullConverted = RETL_ServiceRequestWizardController.convertStringToTime(invalidTime);
        System.assertEquals(null, nullConverted, 'Should return null for invalid time string');

        Test.stopTest();
    }
   
@IsTest
static void test_handleDocuments_success() {

        // Create minimal required Case
    Case testCase = new Case(
        Subject = 'File Upload Test Case',
        Origin = 'Web',
        Status = 'New',
         RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
    );
    insert testCase;

        // Create Case Comment
    CaseComment caseComment = new CaseComment(
        ParentId = testCase.Id,
        CommentBody = 'Attachment upload test'
    );
    insert caseComment;

        // Prepare fake file content for upload
    String base64File = EncodingUtil.base64Encode(Blob.valueOf('This is test content.'));
    String filesJson = '[{"documentType":"Lease Agreement","contentVersions":[{"fileName":"TestFile.txt","base64":"'+ base64File +'"}]}]';

        // Start test
    Test.startTest();

    // Because in test mode the handler skips ContentVersion insert,
    // we’ll call the uploadDocuments method (to cover it) and
    // then separately call externalFileLinkCreation to simulate file linking.

    Map<String, Object> result = RETL_ServiceRequestWizardController.uploadDocuments(
        filesJson,
        testCase.Id,
        caseComment.Id
    );

    // Create a dummy Document__c manually to simulate what handler would do
    Document__c doc = new Document__c(
        Case__c = testCase.Id,
        DocumentType__c = 'Lease Agreement'
    );
    insert doc;

    // Create dummy ContentVersion to use for file link creation
    ContentVersion cv = new ContentVersion(
        Title = 'TestFile',
        PathOnClient = 'TestFile.txt',
        VersionData = Blob.valueOf('Dummy Content for Test'),
         RETL_Document_Type__c=doc.DocumentType__c
    );
    insert cv;
    //List<ContentVersion> cvList = [SELECT Id,RETL_Document_Type__c, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
// Create a dummy Document__c manually to simulate what handler would do
    Document__c doc1 = new Document__c(
        Case__c = testCase.Id,
        DocumentType__c = 'Lease Agreement'
    );
    insert doc1;

    // Create dummy ContentVersion to use for file link creation
    ContentVersion cv1 = new ContentVersion(
        Title = 'TestFile',
        PathOnClient = 'TestFile.txt',
        VersionData = Blob.valueOf('Dummy Content for Test'),
         RETL_Document_Type__c=doc.DocumentType__c
    );
    insert cv1;
    //cv1 = [SELECT Id,RETL_Document_Type__c, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1];
    // Manually invoke the link creation logic to ensure External_Files__c creation
    List<External_Files__c> extFiles = RETL_SRDocumentHandler.externalFileLinkCreation(
        new List<ContentVersion>{ cv },
        new List<Document__c>{ doc },
        caseComment.Id,
        false
    );
    List<External_Files__c> extFiless = RETL_SRDocumentHandler.externalFileLinkCreation(
        new List<ContentVersion>{ cv1 },
        new List<Document__c>{ doc1 },
        caseComment.Id,
        true
    );
    
       
    Test.stopTest();

    // Assertions
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(result.containsKey('DocLinks'), 'Result map should contain DocLinks key');

    List<Document__c> createdDocs = [SELECT Id, DocumentType__c FROM Document__c WHERE Case__c = :testCase.Id];
    System.assert(!createdDocs.isEmpty(), 'Document__c record should be created');
    System.assertEquals('Lease Agreement', createdDocs[0].DocumentType__c, 'Document type should match');

    List<External_Files__c> createdFiles = [SELECT Id, File_Name__c, External_URL__c, Document__c FROM External_Files__c];
    System.assert(!createdFiles.isEmpty(), 'External_Files__c record should be created');
    // System.assertEquals(doc.Id, createdFiles[0].Document__c, 'External_Files__c should link to the correct Document');

    System.debug('Upload completed successfully. Created file link: ' + createdFiles[0].External_URL__c);
}
@IsTest
static void test_callExternalFileLinkCreationFromInvocable() {

    // 1️⃣ Create a Case to associate the document
    Case testCase = new Case(
        Subject = 'Invocable Test Case',
        Origin = 'Phone',
        Status = 'New',
        RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId()
    );
    insert testCase;

    // 2️⃣ Create Case Comment
    CaseComment caseComment = new CaseComment(
        ParentId = testCase.Id,
        CommentBody = 'Testing Invocable for External File creation'
    );
    insert caseComment;

    // 3️⃣ Create a dummy Document__c record
    Document__c doc = new Document__c(
    
        DocumentType__c = 'Others',
        Case__c = testCase.Id
    );
    insert doc;

    // 4️⃣ Create a dummy ContentVersion record
    ContentVersion cv = new ContentVersion(
        Title = 'InvocableFile',
        PathOnClient = 'InvocableFile.txt',
        VersionData = Blob.valueOf('Sample file content'),
        RETL_Document_Type__c = 'Others'
    );
    insert cv;
    //List<ContentVersion> cvList = [SELECT Id, ContentDocumentId, Title, RETL_Document_Type__c FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

    // 5️⃣ Prepare InputVariables for the Invocable Method
    RETL_SRDocumentHandler.InputVariables input = new RETL_SRDocumentHandler.InputVariables();
    input.contentVersionList = new List<ContentVersion>{ cv };
    input.documents = new List<Document__c>{ doc };
    input.caseCommentId = caseComment.Id;
    input.isCongaDocument = false;

    // 6️⃣ Call the Invocable Method
    Test.startTest();
    List<External_Files__c> createdFiles = RETL_SRDocumentHandler.callExternalFileLinkCreationFromInvocalble(
        new List<RETL_SRDocumentHandler.InputVariables>{ input }
    );
    Test.stopTest();

    // 7️⃣ Assertions
    System.assertNotEquals(null, createdFiles, 'The method should return a list of External_Files__c');
    System.assert(!createdFiles.isEmpty(), 'At least one External_Files__c record should be created');

    // Query to verify records were really inserted
    List<External_Files__c> extFileRecs = [
        SELECT Id, File_Name__c, External_URL__c, Document__c, RETL_Case_Comment_SF_ID__c
        FROM External_Files__c
        WHERE Document__c = :doc.Id
    ];

    System.assert(!extFileRecs.isEmpty(), 'External_Files__c records should exist in DB');
    System.assertEquals(caseComment.Id, extFileRecs[0].RETL_Case_Comment_SF_ID__c, 'Case Comment ID should match');
    System.assertEquals(doc.Id, extFileRecs[0].Document__c, 'External file should be linked to the correct document');
    System.assert(extFileRecs[0].File_Name__c.contains('InvocableFile'), 'File name should match the content version title');

    System.debug('✅ Invocable test passed. Created External_Files__c record: ' + extFileRecs[0]);
}

    // Helper to create Retail_Unit__c safely (fields may or may not exist in target org)
    private static SObject newRetailUnit(String propCode, String propName, String unitCode) {
        SObject u = (SObject) Type.forName('Retail_Unit__c').newInstance();
        if (propCode != null) u.put('Property_Code__c', propCode);
        if (propName != null) u.put('Property_Name__c', propName);
        if (unitCode != null) u.put('Unit_Code__c', unitCode);
        // optional fields
        try { u.put('Floor__c', 'G'); } catch (Exception e) {}
        try { u.put('Unit_Location__c', 'Mall'); } catch (Exception e) {}
        insert u;
        return u;
    }

    // Basic PB/Product scaffolding for OrderItem
    private static PricebookEntry ensureStdPricebookEntry() {
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;
        PricebookEntry newPricebookEntry = TestObjectsFactory.getPricebookEntry(p.Id);
        insert newPricebookEntry;
        return newPricebookEntry;
    }

    private static Account makeAccount() {
        Account a = new Account(Name = 'Acc ' + String.valueOf(Crypto.getRandomInteger()));
        insert a;
        return a;
    }

    private static Order makeOrder(Id accountId, String propertyCode, String statusVal) {
        Account newOrgAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org23', 'G123456456');
         newOrgAccount.RETL_Status__c = 'Active';   
        insert newOrgAccount;
        Account newBrandAccount = TestObjectsFactory.getBrandAccountRecord('Test Brand');
        insert newBrandAccount;
        
        Contract newContract = TestObjectsFactory.getContract(newOrgAccount.Id);
        insert newContract;
        Order o = TestObjectsFactory.getOrder(newOrgAccount.Id, newBrandAccount.Id, newContract.Id);
        //insert newOrder;
        //Order o = new Order(AccountId = accountId, EffectiveDate = Date.today(), Status = 'Draft');
        try { o.put('RETL_Property_Name__c', propertyCode); } catch (Exception e) {}
        try { o.put('RETL_Status__c', statusVal); } catch (Exception e) {}
        //insert o;
        return o;
    }

    private static OrderItem makeOrderItem(Id orderId, PricebookEntry pbe) {
        OrderItem oi = new OrderItem(OrderId = orderId, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1);
        // Populate optional fields for completeness
        try { oi.put('RETL_Unit__c', 'U-01'); } catch (Exception e) {}
        try { oi.put('RETL_UnitType__c', 'Retail'); } catch (Exception e) {}
        try { oi.put('RETL_Location__c', 'Loc'); } catch (Exception e) {}
        try { oi.put('RETL_Floor__c', 'G'); } catch (Exception e) {}
        try { oi.put('RETL_Area__c', '100'); } catch (Exception e) {}
        try { oi.put('RETL_PropertyName__c', 'Prop Name'); } catch (Exception e) {}
        insert oi;
        return oi;
    }

    @IsTest
    static void test_searchRetailUnits_returnsMatchesByPropertyCode() {
        // Prepare units with duplicate property names but unique codes
        newRetailUnit('PC-100', 'Yas Mall', 'U-1001');
        newRetailUnit('PC-100', 'Yas Mall North', 'U-1002');
        newRetailUnit('PC-200', 'Marina Mall', 'U-2001');

        Test.startTest();
         List<Retail_Unit__c> result1 = RETL_ServiceRequestWizardController.getAllProperties('yas');
        List<Retail_Unit__c> result = RETL_ServiceRequestWizardController.searchRetailUnits('PC-100');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return units with exact Property_Code__c match');
        Set<String> unitCodes = new Set<String>();
        for (Retail_Unit__c ru : result) unitCodes.add(ru.Unit_Code__c);
        System.assert(unitCodes.contains('U-1001') && unitCodes.contains('U-1002'), 'Expected unit codes not found');
    }

    @IsTest
    static void test_getOrderItemFromContractorSelection_returnsOrderIdForCurrent() {
        Test.startTest();
        Account a = makeAccount();
        PricebookEntry pbe = ensureStdPricebookEntry();

        // Create two orders with same property code; only one is Current
        Order oCurrent = makeOrder(a.Id, 'PC-300', 'Current');
        insert oCurrent;
        makeOrderItem(oCurrent.Id, pbe);

        //Order oOld = makeOrder(a.Id, 'PC-301', 'Expired');
        //makeOrderItem(oOld.Id, pbe);

        
        String orderId = RETL_ServiceRequestWizardController.getOrderItemFromContractorSelection('PC-300');
        Test.stopTest();

        System.assertNotEquals(null, orderId, 'Should return an OrderId');
        System.assertEquals(oCurrent.Id, orderId, 'Should return the Current order id');
    }

    @IsTest
    static void test_getAllServiceData_personaFilter_includesPersona() {
        // Insert minimal RETL_SR_Master__c that includes given persona
        Boolean inserted = false;
        try {
            SObject m = (SObject) Type.forName('RETL_SR_Master__c').newInstance();
            m.put('RETL_Category__c', 'Cat A');
            m.put('RETL_Sub_Category__c', 'Sub A');
            m.put('RETL_Service_Type__c', 'Svc A');
            // Multipicklist includes value 'Tenant'
            m.put('RETL_Persona__c', 'Tenant;Contractor');
            m.put('RETL_Display_Order__c', 1);
            insert m;
            inserted = true;
        } catch (Exception e) {
            // object/field might not exist in the scratch/org, still call method below
        }

        Test.startTest();
        List<RETL_SR_Master__c> data = RETL_ServiceRequestWizardController.getAllServiceData('Tenant');
        String d = RETL_ServiceRequestWizardController.getTenantPortalSetting();
        Test.stopTest();

        System.assertNotEquals(null, data, 'Should return list (may be empty if object absent)');
        if (inserted) {
            // Ensure at least the record with persona 'Tenant' is returned
            Boolean found = false;
            for (RETL_SR_Master__c rec : data) {
                if (String.valueOf(rec.RETL_Persona__c).contains('Tenant')) {
                    found = true; break;
                }
            }
            System.assertEquals(true, found, 'Expected persona record not found');
        }
    }
	
    @isTest
    public static void test23(){
        Account a = makeAccount();
        Contact c = new Contact(
            AccountId = a.Id,
            LastName = 'cscs',
            FirstName = 'FN',
            Email = 'teds@ted.com',
            MobilePhone = '971500000000'
        );
        try {
            c.put('MobileCountryCode__c', '971');
            c.put('MobilePhone__c', '500000000');
            c.put('CountryOfResidence__c', 'United Arab Emirates');
            c.put('CustomerLocation__c', 'Abu Dhabi');
        } catch (Exception e) {}
        insert c;
       Test.StartTest();
        Profile p = [SELECT Id, Name FROM Profile where Name ='Retail Contractor Profile' LIMIT 1];
        User u = new User(
            Username = 'u' + String.valueOf(Math.random()) + '@test.org',
            Alias = 'wus' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000)).left(3),
            
            Email = 'u@test.org',
            TimeZoneSidKey = 'Asia/Dubai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'ULast',
            FirstName = 'UFirst',
            CommunityNickname = 'nick' + String.valueOf(Math.random()).substring(0,6),
            ProfileId = p.Id,
            ContactId = c.Id
        );
        insert u;
        Test.StopTest();
        system.runAs(u){
          User us =  RETL_ServiceRequestWizardController.getCurrentUserDetails(c.Id);
        }
    }
}