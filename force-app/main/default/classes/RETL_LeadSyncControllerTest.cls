@IsTest
private class RETL_LeadSyncControllerTest {

    private static Account testAccount;
    private static Account testAccountGroup;
    private static Account testAccountBrand;
    private static Opportunity testOpportunity;
    private static Contact testContact;
    private static ContentVersion testContentVersion;
    private static Account tradeLicenseAccount;
    private static RecordType oppRecordType;

    private static Id standardPricebookId;
    private static Id retailPricebookId;
    private static Retail_Unit__c unit1;
    private static Retail_Unit__c unit2;
    private static Product2 product1;
    private static Product2 product2;

    // -----------------------------
    // Test Data Setup
    // -----------------------------
    private static void setupData() {

        // Group
        // 1. Account
        testAccountGroup = new Account(
            Name = 'Test Group',
            Type = 'Group',
            RETL_Yardi_Id__c = 'ACCT_YARDI_GRP_001'            
        );
        insert testAccountGroup;

        //Brand
        testAccountBrand = new Account(
            Name = 'Test Brand',
            Type = 'Brand',
            RETL_Yardi_Id__c = 'ACCT_YARDI_BRD_001',
            RETL_Group__c = testAccountGroup.id
        );
        insert testAccountBrand;

        // 1. Account
        testAccount = new Account(
            Name = 'Test Account',
            RETL_Yardi_Id__c = 'ACCT_YARDI_001',
            RETL_Group__c = testAccountGroup.id
        );
        insert testAccount;

        // Trade License Account
        tradeLicenseAccount = new Account(
            Name = 'Trade License Account',
            ParentId = testAccount.Id,
            Type = 'Trade License',
            RETL_Yardi_Id__c = 'TL_YARDI_001'
        );
        insert tradeLicenseAccount;

        // 2. RecordType for Opportunity
        oppRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='RETL_Opportunity' LIMIT 1];
		System.debug('oppRecordType=='+oppRecordType);

        // 3. Opportunity
        testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            RETL_Yardi_Id__c = 'OPP_YARDI_001',
            RETL_Lead_Financial_Yardi_Id__c = 'FIN_YARDI_001',
            RETL_Brand__c = testAccountBrand.id,
            RETL_AM_PreApproval__c = 'Approved',
            RecordTypeId = oppRecordType.Id
            //RETL_Group__c = testAccountGroup.Id
           
        );
        insert testOpportunity;
        System.debug('testOpportunity.RecordTypeId=='+testOpportunity.RecordTypeId);

        // 1. Pricebooks
        standardPricebookId = Test.getStandardPricebookId();
        system.debug(standardPricebookId);

        Pricebook2 retailPB = new Pricebook2(Name = 'Retail Price Book', IsActive = true);
        insert retailPB;
        retailPricebookId = retailPB.Id;

        // 2. Retail Units
        unit1 = new Retail_Unit__c(            
            Unit_Code__c = 'A101',           
            UnitID_External_ID__c = 'YARDI_123',
            Property_Name__c = 'Test Property One',
            Unit_Status__c = 'Near Expiry',
            Unit_Type__c = 'Kiosk',
            Unit_Area__c = 100.0,
            Rent_Budget__c = 50.0, // Per SQM
            Net_Service_Charge_Budget__c = 10.0, // Per SQM
            Amount_Type__c = 'Per Sqm'
            
        );
        unit2 = new Retail_Unit__c(           
            Unit_Code__c = 'B202',            
            UnitID_External_ID__c = 'YARDI_456',
            Property_Name__c = 'Test Property Two',
            Unit_Status__c = 'On Hold',
            Unit_Type__c = 'Retail Shop',
            Unit_Area__c = 250.0,
            Rent_Budget__c = 10000.0, // Flat Amount
            Net_Service_Charge_Budget__c = 2000.0, // Flat Amount
            Amount_Type__c = 'Flat Amount'
            
        );
        insert new List<Retail_Unit__c>{ unit1, unit2 };

        // 3. Products for Unit 1 (pre-existing)
        product1 = new Product2(
            Name = unit1.Unit_Code__c,
            ProductCode = unit1.Unit_Code__c,
            RETL_Yardi_Id__c = unit1.UnitID_External_ID__c,
            IsActive = true
        );
        insert product1;

        // 4. Pricebook Entries for Product 1 (pre-existing)
        // Standard PBE
        PricebookEntry pbeStd1 = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product1.Id,
            UnitPrice = 0,
            IsActive = true,
            RETL_External_ID__c = standardPricebookId + '-' + product1.RETL_Yardi_Id__c
        );
        // Retail PBE
        PricebookEntry pbeRetail1 = new PricebookEntry(
            Pricebook2Id = retailPricebookId,
            Product2Id = product1.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pbeStd1, pbeRetail1 };

       
         // Insert OLI
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 1,
            UnitPrice = 1000,
            PricebookEntryId = pbeRetail1.Id,
            RETL_Service_Charge__c = 200,
            RETL_Marketing_Amount__c = 300,
            RETL_Rent_Free_Amount__c = 100,
            RETL_Fitout_Contribution_Amount__c = 50,
            RETL_Selected_Unit__c = unit1.Id
        );
        insert oli;

        // 5. Contact and Contact Role
        testContact = new Contact(
            FirstName='Test',
            LastName='Contact',
            AccountId = testAccount.Id,
            RETL_Yardi_Id__c='CONT_YARDI_001'
        );
        insert testContact;

        /* // Assume Contact_Roles__r relationship exists
        RETL_Contact_role__c contactRole = new RETL_Contact_role__c(
            RETL_Contact__c = testContact.Id,
            RETL_Yardi_Id__c = 'ROLE_YARDI_001'
        );
        insert contactRole; */

        // 6. ContentVersion & ContentDocumentLink
        testContentVersion = new ContentVersion(
            Title = 'Brand Profile - Test',
            PathOnClient = 'BrandProfile.pdf',
            VersionData = Blob.valueOf('Test')
        );
        insert testContentVersion;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId,
            LinkedEntityId = testContact.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    // -----------------------------
    // Test getYardiRelatedInfo
    // -----------------------------
    @IsTest
    static void testGetYardiRelatedInfo() {
        setupData();

        Test.startTest();
        Map<String,String> result = RETL_LeadSyncController.getYardiRelatedInfo(testOpportunity.Id);
        Test.stopTest();

        System.assertEquals('Approved', result.get('PreApprovalStatus'));
        System.assertEquals('1', result.get('OpportunityLineItemCount'));
        System.assertEquals('OPP_YARDI_001', result.get('OpportunityYardiId'));
        System.assertEquals('FIN_YARDI_001', result.get('OpportunityFinanceYardiId'));
        System.assertEquals('ACCT_YARDI_001', result.get('AccountYardiId'));
        System.assertEquals('ACCT_YARDI_GRP_001', result.get('GroupYardiId'));
        System.assertEquals('CONT_YARDI_001', result.get('ContactYardiId'));
        //System.assertEquals('ROLE_YARDI_001', result.get('ContactRoleYardiId'));
        System.assertEquals(testContentVersion.RETL_Yardi_Id__c, result.get('ContentVersionYardiId'));
        System.assertEquals(tradeLicenseAccount.Id, result.get('TradeLicenseAccountId'));
    }

    @IsTest
    static void testGetYardiRelatedInfo_NullOpportunity() {
        Test.startTest();
        try {
            RETL_LeadSyncController.getYardiRelatedInfo(null);
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            
        }
        Test.stopTest();
    }

    private class YardiMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // Exact sample response provided
            res.setBody('{' +
                '"Status": "Success",' +
                '"ErrorMessage": "Lead Imported Successfully",' +
                '"SF_Ref_Lead_ID": "SF_Ref_Lead_Id-7",' +
                '"LeadCode": "cp05509"' +
            '}');

            return res;
        }
    }

    // -----------------------------
    // Test syncOpportunityToYardi
    // -----------------------------
    @IsTest
    static void testSyncOpportunityToYardi() {
        setupData();
        Test.setMock(HttpCalloutMock.class, new YardiMockSuccess());
        // Mock RETL_LeadSyncToYardi class
        Test.startTest();
        String result = RETL_LeadSyncController.syncOpportunityToYardi(testOpportunity.Id);
        Test.stopTest();

        System.assert(result.contains('Yardi sync initiated successfully'));
    }
    @IsTest
static void test_syncOpportunityToYardi_nullId() {
    Test.startTest();
    try {
        RETL_LeadSyncController.syncOpportunityToYardi(null);
        System.assert(false, 'Exception should have been thrown for null Opportunity Id');
    } catch (AuraHandledException e) {
        // AuraHandledException message is often "Script-thrown exception" in tests
        System.assertNotEquals(
            null,
            e,
            'AuraHandledException should be thrown'
        );
    }
    Test.stopTest();
}

    /* @IsTest
    static void testSyncOpportunityToYardi_NullOpportunity() {
        Test.startTest();
        try {
            RETL_LeadSyncController.syncOpportunityToYardi(null);
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Opportunity Id is required.'));
        }
        Test.stopTest();
    } */

    // -----------------------------
    // Test pushLCApprovalToYardi
    // -----------------------------
    @IsTest
    static void testPushLCApprovalToYardi() {
        setupData();

        Test.startTest();
        RETL_LeadSyncController.pushLCApprovalToYardi(testOpportunity.Id);
        Test.stopTest();
        // No assertion, just coverage
    }

    // -----------------------------
    // Test updateOpportunityStageAndReason
    // -----------------------------
    @IsTest
    static void testUpdateOpportunityStageAndReason() {
        setupData();

        Test.startTest();
        Id clonedId = RETL_LeadSyncController.updateOpportunityStageAndReason(
            testOpportunity.Id, 
            'Closed Lost', 
            'Lost - Unit Change', 
            'Client decision', 
            'CloneAndCancel'
        );
        RETL_LeadSyncController.syncProposalToYardi (testOpportunity.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT StageName, LossReason__c, LossComments__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Closed Lost', updatedOpp.StageName);
        System.assertEquals('Lost - Unit Change', updatedOpp.LossReason__c);
        System.assertEquals('Client decision', updatedOpp.LossComments__c);

        // Check cloned opp exists
        System.assertNotEquals(null, clonedId);
        Opportunity clonedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :clonedId];
        System.assertEquals('Deal In Progress', clonedOpp.StageName);
    }

}