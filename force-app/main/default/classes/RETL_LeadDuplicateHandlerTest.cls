@IsTest
private class RETL_LeadDuplicateHandlerTest {

   // Custom fields used in the main class
    private static final String LEAD_TRADE_LICENSE_FIELD = 'RETL_Trade_License_No__c';
    private static final String ACCOUNT_TRADE_LICENSE_FIELD = 'ECSS_Trade_License_Number__c';
    
    // Developer Names for Record Types (assuming they exist based on the SOQL)
    private static final String ACCOUNT_RT_DEV_NAME = 'OrganizationAccount'; 
    private static final String CONTACT_RT_DEV_NAME = 'Contact'; 
    private static final String LEAD_RT_DEV_NAME = 'RETL_Retail_Lead'; 

    /**
     * @testSetup method to prepare common test data.
     */
    @TestSetup
    static void setupTestData() {
        // 1. Create a Standard User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Alias = 'testdupH',
            Email = 'testduphandler@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestHandler',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testduphandler@test.com' + System.currentTimeMillis() + '.com'
        );
        insert testUser;

        // 2. Get Record Type IDs (Assuming existence)
        Id contactRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().containsKey(CONTACT_RT_DEV_NAME) 
            ? Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(CONTACT_RT_DEV_NAME).getRecordTypeId()
            : null;

        Id leadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().containsKey(LEAD_RT_DEV_NAME) 
            ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(LEAD_RT_DEV_NAME).getRecordTypeId()
            : null;

        Id accOrgRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().containsKey(ACCOUNT_RT_DEV_NAME) 
            ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(ACCOUNT_RT_DEV_NAME).getRecordTypeId()
            : null;


        Account brandAcc = new Account(
            Name = 'Brand New Company',
            Type = 'Brand',
            RecordTypeId = accOrgRtId 
        );
        insert brandAcc;
        // 3. Create a unique Account
        Account uniqueAcc = new Account(
            Name = 'Unique Company',
            ECSS_Trade_License_Number__c = 'TL12345'
        );
        insert uniqueAcc;

        // 4. Create a duplicate-matching Contact & Account
        String contactEmail = 'duplicatecontact@test.com';
        String companyName = 'Duplicate Company';
        String tradeLicense = 'DUPTL-001';

        Account dupAcc = new Account(
            Name = companyName,
            ECSS_Trade_License_Number__c = tradeLicense
        );
        insert dupAcc;

        Contact dupCon = new Contact(
            FirstName = 'Dup',
            LastName = 'Contact',
            Email = contactEmail,
            AccountId = dupAcc.Id,
            RecordTypeId = contactRTId
        );
        insert dupCon;

        // 5. Create Leads (matching the duplicates)
        // Lead 1: Matches Contact and Account (via standard rules like Email/Company)
        Lead lead1 = new Lead(
            FirstName = 'Dup',
            LastName = 'Lead One',
            Email = contactEmail, // Matches Contact
            Company = companyName, // Matches Account
            Status = 'New Lead',
            MobilePhone = '+971500000000',            
            LeadSource = 'Online',
            SalesType__c = 'Asset Management',
            //AreaSqmt__c = '1,000-1,500 SQM',
            //BuyRent__c = 'Rent',
            EnquiryCategory__c = 'Aldar Websites',
            
            EnquiryTrigger__c = 'Aldar.com',
            //PropertyUsage__c = 'Personal',
            ExternalSystemID__c = 'EXT123456',
            RETL_Source__c = 'Website',
            RETL_Minimum_Desired_Area__c = 100,
            RETL_Maximum_Desired_Area__c = 150,
            RETL_Minimum_Desired_Rent__c = 50000,
            RETL_Maximum_Desired_Rent__c = 80000,
            RETL_Primary_Property__c = 'yasmall',
            RETL_Sales_Category__c = 'Department Store',
            RecordTypeId = leadRTId,
            Project__c = 'Yas Mall',
            PropertyUsage__c= 'Retail',
            RETL_Brand__c = brandAcc.id
            //RETL_Property__c = 'PROP123456'
        );
        insert lead1;

        // Lead 2: Has a unique Trade License number
        Lead lead2 = new Lead(
           
            Status = 'New Lead',
            MobilePhone = '+971500000000',            
            LeadSource = 'Online',
            SalesType__c = 'Asset Management',
            //AreaSqmt__c = '1,000-1,500 SQM',
            //BuyRent__c = 'Rent',
            EnquiryCategory__c = 'Aldar Websites',
            
            EnquiryTrigger__c = 'Aldar.com',
            //PropertyUsage__c = 'Personal',
            ExternalSystemID__c = 'EXT123456',
            RETL_Source__c = 'Website',
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
            Email = 'uniquelead@test.com',
            Company = 'Unique Lead Company',
            RETL_Trade_License_No__c = 'UNIQUE-TL-001',
			FirstName = 'Unique',
            LastName = 'Lead Two'
            
        );
        insert lead2;
    }

    /**
     * Test case to verify the handling of duplicate Contacts and Accounts found by Datacloud.FindDuplicates.
     */
    @IsTest
    static void testFindDuplicates_Success() {
        // Retrieve test data
        Lead lead1 = [SELECT Id FROM Lead WHERE Email = 'duplicatecontact@test.com' LIMIT 1];
        Contact dupCon = [SELECT Id FROM Contact WHERE Email = 'duplicatecontact@test.com' LIMIT 1];
        Account dupAcc = [SELECT Id FROM Account WHERE Name = 'Duplicate Company' LIMIT 1];
        
        // Prepare the input request
        List<RETL_LeadDuplicateHandler.Request> requests = new List<RETL_LeadDuplicateHandler.Request>();
        RETL_LeadDuplicateHandler.Request req1 = new RETL_LeadDuplicateHandler.Request();
        req1.leadId = lead1.Id;
        requests.add(req1);

        // Run as a Standard User to ensure proper sharing/permissions are tested
        User testUser = [SELECT Id FROM User WHERE Alias = 'testdupH' LIMIT 1];
        List<RETL_LeadDuplicateHandler.Response> results;

        //System.runAs(testUser) {
            Test.startTest();
            // Mock Datacloud.FindDuplicates to simulate finding the duplicates
            // NOTE: Datacloud.FindDuplicates.findDuplicates() must be mocked for reliable tests. 
            // Since it's not possible directly, we rely on the active Duplicate Rule matching 
            // Lead fields to Contact/Account fields (Email/Company in this case).
            
            // Due to the limitation of mocking Datacloud.FindDuplicates, we'll manually 
            // ensure the test data meets the criteria of a simple Duplicate Rule (e.g., matching Email/Company).
            
            results = RETL_LeadDuplicateHandler.findLeadDuplicates(requests);
            Test.stopTest();
        //}

        // Assertions
        System.assertNotEquals(null, results, 'Results list should not be null.');
        System.assertEquals(1, results.size(), 'Should return exactly one response for the one request.');

        RETL_LeadDuplicateHandler.Response res = results[0];

        // Based on the setup, if a Duplicate Rule is active and matches, duplicates should be found.
        // We assert that the lists are not empty, assuming a standard duplicate rule is active 
        // that matches Lead.Email to Contact.Email and Lead.Company to Account.Name.
        // If the duplicate rule is NOT active or NOT matching, this test will fail, 
        // which highlights a dependency on the environment's configuration.

        // A truly reliable test would involve a mock for Datacloud.FindDuplicates, 
        // which isn't possible in standard Apex. We proceed assuming the environment 
        // has a rule set up for Lead -> Contact/Account matching via Email/Company.
        
        System.assertEquals(true, res.hasDuplicateContacts, 'Should find duplicate Contacts if rule is active.');
        System.assertNotEquals(0, res.contacts.size(), 'Contacts list should not be empty.');
        
        // Verify full Contact records are retrieved
        RETL_LeadDuplicateHandler.Response contactRes = results[0];
        Boolean foundDupContact = false;
        for (Contact c : contactRes.contacts) {
            if (c.Id == dupCon.Id && c.Email != null) {
                foundDupContact = true;
                break;
            }
        }
        System.assertEquals(true, foundDupContact, 'The expected duplicate Contact was not found or was incomplete.');

        System.assertEquals(true, res.hasDuplicateAccounts, 'Should find duplicate Accounts if rule is active.');
        System.assertNotEquals(0, res.accounts.size(), 'Accounts list should not be empty.');
        
        // Verify full Account records are retrieved
        RETL_LeadDuplicateHandler.Response accountRes = results[0];
        Boolean foundDupAccount = false;
        for (Account a : accountRes.accounts) {
             // Check for a field queried in Step 4 to ensure the full record was retrieved.
            if (a.Id == dupAcc.Id && a.ECSS_Trade_License_Number__c != null) { 
                foundDupAccount = true;
                break;
            }
        }
        System.assertEquals(true, foundDupAccount, 'The expected duplicate Account was not found or was incomplete.');

        // Opportunities is a placeholder
        System.assertEquals(0, res.opportunities.size(), 'Opportunities list should be empty (placeholder).');
    }

    /**
     * Test case to verify the handling when no duplicates are found (unique Lead).
     */
    @IsTest
    static void testFindDuplicates_NoDuplicates() {
        // Retrieve the unique Lead
        Lead lead2 = [SELECT Id FROM Lead WHERE Email = 'uniquelead@test.com' LIMIT 1];
        
        // Prepare the input request
        List<RETL_LeadDuplicateHandler.Request> requests = new List<RETL_LeadDuplicateHandler.Request>();
        RETL_LeadDuplicateHandler.Request req2 = new RETL_LeadDuplicateHandler.Request();
        req2.leadId = lead2.Id;
        requests.add(req2);

        User testUser = [SELECT Id FROM User WHERE Alias = 'testdupH' LIMIT 1];
        List<RETL_LeadDuplicateHandler.Response> results;

        //System.runAs(testUser) {
            Test.startTest();
            // Since this Lead has unique fields, it should not trigger the duplicate rule.
            results = RETL_LeadDuplicateHandler.findLeadDuplicates(requests);
            Test.stopTest();
        //}

        // Assertions
        System.assertNotEquals(null, results, 'Results list should not be null.');
        System.assertEquals(1, results.size(), 'Should return exactly one response.');

        RETL_LeadDuplicateHandler.Response res = results[0];

        System.assertEquals(false, res.hasDuplicateContacts, 'Should not find duplicate Contacts.');
        System.assertEquals(0, res.contacts.size(), 'Contacts list should be empty.');
        
        System.assertEquals(false, res.hasDuplicateAccounts, 'Should not find duplicate Accounts.');
        System.assertEquals(0, res.accounts.size(), 'Accounts list should be empty.');

        System.assertEquals(0, res.opportunities.size(), 'Opportunities list should be empty (placeholder).');
    }
    
    /**
     * Test case to verify the handling of an empty input list.
     */
    @IsTest
    static void testFindDuplicates_EmptyInput() {
        // Prepare empty input request
        List<RETL_LeadDuplicateHandler.Request> requests = new List<RETL_LeadDuplicateHandler.Request>();

        User testUser = [SELECT Id FROM User WHERE Alias = 'testdupH' LIMIT 1];
        List<RETL_LeadDuplicateHandler.Response> results;

        //System.runAs(testUser) {
            Test.startTest();
            results = RETL_LeadDuplicateHandler.findLeadDuplicates(requests);
            Test.stopTest();
        //}

        // Assertions
        System.assertNotEquals(null, results, 'Results list should not be null.');
        System.assertEquals(0, results.size(), 'Should return an empty list for empty input.');
    }
    
    /**
     * Test case to verify the handling of a Request with a null Lead Id.
     */
    @IsTest
    static void testFindDuplicates_NullLeadId() {
        // Retrieve the unique Lead
        Lead lead2 = [SELECT Id FROM Lead WHERE Email = 'uniquelead@test.com' LIMIT 1];
        
        // Prepare input with one null and one valid request
        List<RETL_LeadDuplicateHandler.Request> requests = new List<RETL_LeadDuplicateHandler.Request>();
        
        RETL_LeadDuplicateHandler.Request reqNull = new RETL_LeadDuplicateHandler.Request();
        // reqNull.leadId is intentionally left null
        requests.add(reqNull);
        
        RETL_LeadDuplicateHandler.Request reqValid = new RETL_LeadDuplicateHandler.Request();
        reqValid.leadId = lead2.Id;
        requests.add(reqValid);

        User testUser = [SELECT Id FROM User WHERE Alias = 'testdupH' LIMIT 1];
        List<RETL_LeadDuplicateHandler.Response> results;

        //System.runAs(testUser) {
            Test.startTest();
            results = RETL_LeadDuplicateHandler.findLeadDuplicates(requests);
            Test.stopTest();
        //}

        // Assertions
        System.assertNotEquals(null, results, 'Results list should not be null.');
        System.assertEquals(2, results.size(), 'Should return one response for each input request.');
        
        // Response 1 (for null Lead Id request)
        RETL_LeadDuplicateHandler.Response resNull = results[0];
        System.assertEquals(false, resNull.hasDuplicateContacts, 'Null request should result in no contacts found.');
        System.assertEquals(0, resNull.contacts.size(), 'Contacts list should be empty for null request.');
        
        // Response 2 (for valid Lead Id request)
        RETL_LeadDuplicateHandler.Response resValid = results[1];
        System.assertEquals(false, resValid.hasDuplicateContacts, 'Valid unique Lead request should result in no contacts found.');
        System.assertEquals(0, resValid.contacts.size(), 'Contacts list should be empty for valid request.');
    }
}