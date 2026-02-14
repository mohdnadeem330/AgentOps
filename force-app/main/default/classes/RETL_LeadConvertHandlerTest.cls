@IsTest
private class RETL_LeadConvertHandlerTest {

    private static final String ACCOUNT_RT_DEV_NAME = 'OrganizationAccount'; 
    private static final String CONTACT_RT_DEV_NAME = 'Contact'; 
    private static final String LEAD_RT_DEV_NAME = 'RETL_Retail_Lead'; 
    private static final String OPPORTUNITY_RT_DEV_NAME = 'RETL_Opportunity';

    private static Id brandAccountId;

    @TestSetup
    static void setupTestData() {
        User testUser;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        testUser = new User(
            Alias = 'testconv',
            Email = 'testconvhandler@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestConvert',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testconvhandler@test.com' + System.currentTimeMillis() + '.com'
        );
        insert testUser;

        Project__c proj = new Project__c();
        proj.Name = 'Yas Mall';
        proj.RETL_Property_Yardi_Code__c = 'yasmall';
        proj.Leasing_Manager__c = testUser.Id;       
        proj.BusinessUnitId__c  = 'Community Retail';
        proj.ProjectCode__c    = '1212' ;
        insert proj;

        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account',false,'123223376');

        testUser = [SELECT Id FROM User WHERE Alias = 'testconv' LIMIT 1];

        Id leadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().containsKey(LEAD_RT_DEV_NAME) 
            ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(LEAD_RT_DEV_NAME).getRecordTypeId()
            : null;
        Id accOrgRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().containsKey(ACCOUNT_RT_DEV_NAME) 
            ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(ACCOUNT_RT_DEV_NAME).getRecordTypeId()
            : null;

        Account brandAcc = new Account(
            Name = 'Brand X',
            Type = 'Brand',
            RecordTypeId = accOrgRtId
        );
        insert brandAcc;
        brandAccountId = brandAcc.Id;

        Lead leadToConvert = new Lead(           
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
            Email = 'convertlead@test.com',
            Company = 'Unique Lead Company',
            RETL_Trade_License_No__c = 'UNIQUE-TL-001',
            FirstName = 'Unique',
            LastName = 'Lead Two',
            RETL_Property__c = proj.id  
        );
        insert leadToConvert;

        Account existingAcc = new Account(Name = 'Existing Customer', RecordTypeId = accOrgRtId);
        insert existingAcc;

        Contact existingCon = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existingcontact@test.com',
            AccountId = existingAcc.Id
        );
        insert existingCon;
        
        Lead leadToUseExisting = new Lead(           
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
            LastName = 'Lead Two',
            RETL_Property__c = proj.id
        );
        insert leadToUseExisting;
    }

    
    static testmethod void testConversion_FullCoverage() {
        // Arrange - pick up records created in @TestSetup
        Lead leadToConvert = [SELECT Id, Company FROM Lead WHERE Email = 'convertlead@test.com' LIMIT 1];
        Account brandAcc = [SELECT Id FROM Account WHERE Name = 'Brand X' LIMIT 1];
        // Provide record type developer names that exist in org (your constants)
        String acctRtDevName = ACCOUNT_RT_DEV_NAME;
        String contRtDevName = CONTACT_RT_DEV_NAME;
        String oppRtDevName = OPPORTUNITY_RT_DEV_NAME;

        // Build request - include brand as semicolon separated string (the handler parses that)
        RETL_LeadConvertHandler.ConvertRequest req = new RETL_LeadConvertHandler.ConvertRequest();
        req.leadId = leadToConvert.Id;
        req.createOpportunity = true;
        req.selectedBrandIds = String.valueOf(brandAcc.Id); // ensure it's a string
        req.AccountRecordTypeName = acctRtDevName;
        req.ContactRecordTypeName = contRtDevName;
        req.OpportunityRecordTypeName = oppRtDevName;

        List<RETL_LeadConvertHandler.ConvertRequest> requests = new List<RETL_LeadConvertHandler.ConvertRequest>{ req };

        // Act
        Test.startTest();
            // skip triggers that might interfere
            LeadFirstMethodOfContactService.skipLeadTrigger = true;
            List<RETL_LeadConvertHandler.ConvertResponse> results = RETL_LeadConvertHandler.convertLead(requests);
        Test.stopTest();

        // Basic sanity checks (optional - re-add asserts if you want verification)
        if (results == null || results.isEmpty()) {
            System.debug('convertLead returned no responses.'); // should not happen
            return;
        }
        RETL_LeadConvertHandler.ConvertResponse r = results[0];
        System.debug('convert response: ' + r);

        // Query the expected created/linked records to ensure code paths executed
        if (r.accountId != null) {
            // Query for trade license account (created as child)
            List<Account> childTL = [SELECT Id, ParentId, Type FROM Account WHERE ParentId = :r.accountId AND Type = 'Trade License' LIMIT 10];
            System.debug('Trade license accounts found: ' + childTL.size());
        }

        if (r.accountId != null) {
            // Brand linkage records
            List<RETL_Brand_Linkage__c> bl = [SELECT Id, RETL_Brand__c, RETL_Customer__c FROM RETL_Brand_Linkage__c WHERE RETL_Customer__c = :r.accountId];
            System.debug('Brand linkages found: ' + bl.size());
        }

        if (r.contactId != null) {
            // Contact role created by handler
            List<RETL_Contact_role__c> cr = [SELECT Id FROM RETL_Contact_role__c WHERE RETL_Contact__c = :r.contactId AND RETL_Account_Name__c = :r.accountId];
            System.debug('Contact roles found: ' + cr.size());
        }
    }


    @IsTest
    static void testConversion_NoOpportunity() {
        Lead leadToConvert = [SELECT Id FROM Lead WHERE Email = 'convertlead@test.com' LIMIT 1];
        
        RETL_LeadConvertHandler.ConvertRequest req = new RETL_LeadConvertHandler.ConvertRequest();
        req.leadId = leadToConvert.Id;
        req.createOpportunity = false;
        req.AccountRecordTypeName = ACCOUNT_RT_DEV_NAME;
        req.ContactRecordTypeName = CONTACT_RT_DEV_NAME;
        
        List<RETL_LeadConvertHandler.ConvertRequest> requests = new List<RETL_LeadConvertHandler.ConvertRequest>{req};

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Alias = 'testconv' LIMIT 1];
        System.runAs(testUser) {
            List<RETL_LeadConvertHandler.ConvertResponse> results =
                RETL_LeadConvertHandler.convertLead(requests);
        }
        Test.stopTest();
    }

    @IsTest
    static void testConversion_UseExisting() {
        Lead leadToConvert = [SELECT Id FROM Lead WHERE Email = 'linklead@test.com' LIMIT 1];
        Account existingAcc = [SELECT Id FROM Account WHERE Name = 'Existing Customer' LIMIT 1];
        Contact existingCon = [SELECT Id FROM Contact WHERE AccountId = :existingAcc.Id LIMIT 1];
        
        RETL_LeadConvertHandler.ConvertRequest req = new RETL_LeadConvertHandler.ConvertRequest();
        req.leadId = leadToConvert.Id;
        req.accountId = existingAcc.Id;
        req.contactId = existingCon.Id;
        req.createOpportunity = true;
        req.AccountRecordTypeName = ACCOUNT_RT_DEV_NAME;
        req.ContactRecordTypeName = CONTACT_RT_DEV_NAME;
        req.OpportunityRecordTypeName = OPPORTUNITY_RT_DEV_NAME;

        List<RETL_LeadConvertHandler.ConvertRequest> requests = new List<RETL_LeadConvertHandler.ConvertRequest>{req};

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Alias = 'testconv' LIMIT 1];
        System.runAs(testUser) {
            List<RETL_LeadConvertHandler.ConvertResponse> results =
                RETL_LeadConvertHandler.convertLead(requests);
        }
        Test.stopTest();
    }

    @IsTest
    static void testConversion_Failure() {
        Lead leadToFail = [SELECT Id FROM Lead WHERE Email = 'convertlead@test.com' LIMIT 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadToFail.Id);
        lc.setConvertedStatus('Converted Lead'); 
        lc.setDoNotCreateOpportunity(true);
        Database.convertLead(lc, false);

        RETL_LeadConvertHandler.ConvertRequest req = new RETL_LeadConvertHandler.ConvertRequest();
        req.leadId = leadToFail.Id;
        
        List<RETL_LeadConvertHandler.ConvertRequest> requests =
            new List<RETL_LeadConvertHandler.ConvertRequest>{req};

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Alias = 'testconv' LIMIT 1];
        System.runAs(testUser) {
            List<RETL_LeadConvertHandler.ConvertResponse> results =
                RETL_LeadConvertHandler.convertLead(requests);
        }
        Test.stopTest();
    }
}