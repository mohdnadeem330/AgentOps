@IsTest
private class RETL_AccountCreationTest {

    private static final String LEAD_RT_DEV_NAME = 'RETL_Retail_Lead'; 
    private static final String BRAND_RT_DEV_NAME = 'RETL_Brand';  
    private static final String GROUP_RT_DEV_NAME = 'OrganizationAccount';

    private static final Id brandRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BRAND_RT_DEV_NAME).getRecordTypeId();
    private static final Id groupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GROUP_RT_DEV_NAME).getRecordTypeId();
    private static final Id leadRTId =  Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(LEAD_RT_DEV_NAME).getRecordTypeId();


    // Mock the external callout for the asynchronous method    
   
    private class MockAccountSyncToYardi implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate a successful HTTP response (status code 200)
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success", "Yardi_Customer_Code": "YC123456"}'); // Adding the Yardi Customer Code
            return res;
        }
    }

    @testSetup
    static void setupTestData() {

        // Create a Group Account
        Account groupAcc = new Account(
            Name = 'Test Group A', 
            Type = 'Group', 
            RecordTypeId = groupRecordTypeId
        );
        insert groupAcc;

        // Create a Brand Account
        Account brandAcc = new Account(
            Name = 'Test Brand B', 
            Type = 'Brand', 
            RecordTypeId = brandRecordTypeId
        );
        insert brandAcc;

        // Create a Lead record
        Lead testLead = new Lead(
            Status = 'New Lead',
            MobilePhone = '+971500000000',   
            MobileCountryCode__c = '7',             
            LeadSource = 'Online',
            SalesType__c = 'Asset Management',
            EnquiryCategory__c = 'Aldar Websites',            
            EnquiryTrigger__c = 'Aldar.com',            
            ExternalSystemID__c = 'EXT123456',
            RETL_Source__c = 'Damascus Website',
            RETL_Minimum_Desired_Area__c = 100,
            RETL_Maximum_Desired_Area__c = 150,
            RETL_Minimum_Desired_Rent__c = 50000,
            RETL_Maximum_Desired_Rent__c = 80000,
            RETL_Primary_Property__c = 'yasmall',
            RETL_Sales_Category__c = 'Department Store',
            RecordTypeId = leadRTId,
            Project__c = 'Yas Mall',
            PropertyUsage__c= 'Retail',
            RETL_Brand__c = brandAcc.id,
            Email = 'linklead@test.com',
            Company = 'Unique Lead Company',
            RETL_Trade_License_No__c = 'UNIQUE-TL-001',
            FirstName = 'Unique',
            LastName = 'Lead'
            //RETL_Property__c = proj.id
        );
        insert testLead;
    }

    // --- Helper to get setup records (ensures local access to @testSetup data) ---
    private static List<SObject> getSetupRecords() {
        Account groupAcc = [SELECT Id FROM Account WHERE Name = 'Test Group A' LIMIT 1];
        Account brandAcc = [SELECT Id FROM Account WHERE Name = 'Test Brand B' LIMIT 1];
        Lead testLead = [SELECT Id, RETL_Brand__c, RETL_Group__c FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        return new List<SObject>{groupAcc, brandAcc, testLead};
    }

    // ----------------------------------------------------------------------------
    // 1. Tests for getLeadDetails
    // ----------------------------------------------------------------------------

    @IsTest
    static void getLeadDetails_Success() {
        Lead testLead = (Lead)getSetupRecords()[2];
        
        Test.startTest();
        Lead resultLead = RETL_AccountCreation.getLeadDetails(testLead.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultLead, 'Lead details should be returned.');
        System.assertEquals(testLead.Id, resultLead.Id, 'Correct Lead ID was returned.');
    }

    @IsTest
    static void getLeadDetails_NullId_ThrowsException() {
        Boolean caughtException = false;
        
        Test.startTest();
        try {
            RETL_AccountCreation.getLeadDetails(null);
        } catch (AuraHandledException e) {            
            caughtException = true;
        }
        Test.stopTest();
        
        System.assert(caughtException, 'Expected AuraHandledException not caught.');
    }

    // ----------------------------------------------------------------------------
    // 2. Tests for createAccount (UpdateLead logic)
    // ----------------------------------------------------------------------------

    @IsTest
    static void createAccount_UpdateLead_Success() {
        List<SObject> records = getSetupRecords();
        Account brandAcc = (Account)records[1];
        Account groupAcc = (Account)records[0];
        Lead testLead = (Lead)records[2];

        Test.startTest();
        RETL_AccountCreation.createAccount(
            'Dummy Name', 
            'UpdateLead', 
            testLead.Id, 
            brandAcc.Id, 
            groupAcc.Id, 
            null, 
            null
        );
        Test.stopTest();

        Lead updatedLead = [SELECT RETL_Brand__c, RETL_Group__c FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(brandAcc.Id, updatedLead.RETL_Brand__c, 'Lead brand association should be updated.');
        System.assertEquals(groupAcc.Id, updatedLead.RETL_Group__c, 'Lead group association should be updated.');
    }

    @IsTest
    static void createAccount_UpdateLead_NullLeadId_ThrowsException() {
        Boolean caughtException = false;
        
        Test.startTest();
        try {
            RETL_AccountCreation.createAccount('Dummy Name', 'UpdateLead', null, null, null, null, null);
        } catch (AuraHandledException e) {            
            caughtException = true;
        }
        Test.stopTest();
        
        System.assert(caughtException, 'Expected AuraHandledException not caught.');
    }

    // ----------------------------------------------------------------------------
    // 3. Tests for createAccount (New Brand logic)
    // ----------------------------------------------------------------------------

    @IsTest
    static void createAccount_NewBrand_Success() {
        Lead testLead = (Lead)getSetupRecords()[2];
        // Use the mock callout
        Test.setMock(HttpCalloutMock.class, new MockAccountSyncToYardi());

        Test.startTest();
        // REMOVED Test.setMock for simplicity, async call won't execute anyway.
        
        Account newBrand = RETL_AccountCreation.createAccount(
            'New Brand Account', 
            'Brand', 
            testLead.Id, 
            null, 
            null, 
            '1234567-001', 
            'FTA'
        );
        Test.stopTest();

        Account createdAccount = [SELECT Id, Name, Type, RecordTypeId, UAEVATRegisterNumber__c, RETL_Tax_Authority__c FROM Account WHERE Id = :newBrand.Id];
        Lead updatedLead = [SELECT RETL_Brand__c, RETL_Group__c FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('New Brand Account', createdAccount.Name, 'Account name mismatch.');
        System.assertEquals('Brand', createdAccount.Type, 'Account type mismatch.');
        System.assertEquals(brandRecordTypeId, createdAccount.RecordTypeId, 'Account RecordType mismatch.');
        System.assertEquals('1234567-001', createdAccount.UAEVATRegisterNumber__c, 'VAT number mismatch.');
        System.assertEquals('FTA', createdAccount.RETL_Tax_Authority__c, 'Tax authority mismatch.');
        
        System.assertEquals(newBrand.Id, updatedLead.RETL_Brand__c, 'Lead Brand should be updated to the new Account ID.');
        System.assertEquals(null, updatedLead.RETL_Group__c, 'Lead Group should remain null.');
    }

    // ----------------------------------------------------------------------------
    // 4. Tests for createAccount (New Group logic)
    // ----------------------------------------------------------------------------

    @IsTest
    static void createAccount_NewGroup_Success() {
        Lead testLead = (Lead)getSetupRecords()[2];
        // Use the mock callout
        Test.setMock(HttpCalloutMock.class, new MockAccountSyncToYardi());

        Test.startTest();
        // REMOVED Test.setMock
        
        Account newGroup = RETL_AccountCreation.createAccount(
            'New Group Account', 
            'Group', 
            testLead.Id, 
            null, 
            null, 
            null, 
            null
        );
        Test.stopTest();

        Account createdAccount = [SELECT Id, Name, Type, RecordTypeId FROM Account WHERE Id = :newGroup.Id];
        Lead updatedLead = [SELECT RETL_Brand__c, RETL_Group__c FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('New Group Account', createdAccount.Name, 'Account name mismatch.');
        System.assertEquals('Group', createdAccount.Type, 'Account type mismatch.');
        System.assertEquals(groupRecordTypeId, createdAccount.RecordTypeId, 'Account RecordType mismatch.');
        
        System.assertEquals(newGroup.Id, updatedLead.RETL_Group__c, 'Lead Group should be updated to the new Account ID.');
        
    }
    
    // ----------------------------------------------------------------------------
    // 5. Tests for createAccount (Exception Handling)
    // ----------------------------------------------------------------------------
    
    @IsTest
    static void createAccount_InvalidType_ThrowsException() {
        Boolean caughtException = false;

        Test.startTest();
        try {
            RETL_AccountCreation.createAccount('Test Name', 'InvalidType', null, null, null, null, null);
        } catch (AuraHandledException e) {            
            caughtException = true;
        }
        Test.stopTest();        
        System.assert(caughtException, 'Expected AuraHandledException not caught.');
    }
    
    @IsTest
    static void createAccount_BlankName_ThrowsException() {
        Boolean caughtException = false;        
        Test.startTest();
        try {
            RETL_AccountCreation.createAccount(null, 'Brand', null, null, null, null, null);
        } catch (AuraHandledException e) {            
            caughtException = true; 
        }
        Test.stopTest();        
        // Final assertion checks only that an exception was caught
        System.assert(caughtException, 'Expected AuraHandledException not caught.');
    }
}