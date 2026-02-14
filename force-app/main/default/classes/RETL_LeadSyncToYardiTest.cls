@IsTest
private class RETL_LeadSyncToYardiTest {

    private static Id standardPricebookId;
    private static Id retailPricebookId;
    private static Retail_Unit__c unit1;
    private static Retail_Unit__c unit2;
    private static Product2 product1;
    private static Product2 product2;
    private static Account testAccount;
    private static Opportunity testOpportunity;
    // ---------------------------------------
    // Mock for MuleSoft HTTP Callout
    // ---------------------------------------
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


    private class YardiMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"Status":"Failed","ErrorMessage":"Server error"}');
            return res;
        }
    }




    // ---------------------------------------
    // Utility method: create test data
    // ---------------------------------------
    private static Opportunity createTestOpportunity() {

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

        // 5. Opportunity and Account
        testAccount = new Account(Name = 'Test Account for Units');
        insert testAccount;
                RecordType opportunityRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'RETL_Opportunity' AND SObjectType = 'Opportunity' LIMIT 1];
        // Insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            RETL_WO_Yardi_Id__c = 'WO123',
            RETL_Total_Base_Rent__c = 5000,
            RETL_Total_Marketing_Amount__c = 300,
            RETL_Total_Service_Charge__c = 200,
            RETL_Total_Rent_Free_Amount__c = 100,
            RETL_Total_FOC_Amount__c = 50,
            RETL_Deposit_Amount__c = 2000,
            RETL_TOR__c = 1,
            RETL_Fitout_Days__c = 45,
            RETL_Special_Conditions__c = 'Special',
            RETL_Permitted_Usage__c = 'Retail',
            RETL_General_Notes__c = 'Notes',
            RETL_Handover_Conditions__c = 'As is',
            RETL_FOC_Information__c = 'FOC Info',
            RETL_AM_PreApproval__c = 'Approved',
            RETL_TOR_Notes__c = 'TOR Detail',
            RETL_Deposit_Notes__c = 'Deposit Detail',
            RETL_Configure_By__c = 'Unit Level',
            RETL_Escalation__c = 5,
            RETL_Billing_Frequency__c = 'Monthly',
            RETL_Term_Start_Date__c = Date.today(),
            RETL_Term_End_Date__c = Date.today().addYears(1),
            AccountId = testAccount.Id,
            Pricebook2Id = retailPricebookId, // Must use the Retail PB for OLI insertion
            recordtypeId = opportunityRecordType.Id
        );
        insert opp;

        // Insert OLI
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
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
        
        return opp;
    }


    // -------------------------------------------------
    // TEST 1: Build Wrapper Coverage
    // -------------------------------------------------
    @IsTest
    static void testBuildOpportunityWrapper() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        RETL_LeadSyncToYardi.YardiOpportunityRequestWrapper wrapper =
            RETL_LeadSyncToYardi.buildOpportunityWrapper(opp.Id); 
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals(1, wrapper.CommProspect.size());
        System.assertEquals(opp.Id, wrapper.CommProspect[0].SF_Ref_Lead_Id);
        System.assertEquals('A101', wrapper.CommProspect[0].Units, 'Unit extraction failed');
    }



    // -------------------------------------------------
    // TEST 2: Success Flow (200 + Success response)
    // -------------------------------------------------
    @IsTest
    static void testPushToYardiSuccess() {
        Opportunity opp = createTestOpportunity();

        Test.setMock(HttpCalloutMock.class, new YardiMockSuccess());

        Test.startTest();
        RETL_LeadSyncToYardi.pushToYardiAndUpdate(opp.Id);
        Test.stopTest();

        Opportunity updated = [SELECT RETL_Yardi_Id__c FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals('cp05509', updated.RETL_Yardi_Id__c, 'Opportunity Yardi ID not updated');
    }


    // -------------------------------------------------
    // TEST 3: Failure Flow (500 error response)
    // -------------------------------------------------
    @IsTest
    static void testPushToYardiFailure() {
        Opportunity opp = createTestOpportunity();

        Test.setMock(HttpCalloutMock.class, new YardiMockFailure());

        Test.startTest();
        try {
            RETL_LeadSyncToYardi.pushToYardiAndUpdate(opp.Id);
        } catch (Exception e) {
            // Expected branch
        }
        Test.stopTest();

        // Should not populate Yardi ID
        Opportunity updated = [SELECT RETL_Yardi_Id__c FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals(null, updated.RETL_Yardi_Id__c);
    }



    // -------------------------------------------------
    // TEST 4: Null OpportunityId handling
    // -------------------------------------------------
    @IsTest
    static void testNullOpportunityId() {
        Test.startTest();
        try {
            RETL_LeadSyncToYardi.pushToYardiAndUpdate(null);
            System.assert(false, 'Exception expected');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Opportunity Id cannot be null'));
        }
        Test.stopTest();
    }


    // -------------------------------------------------
    // TEST 5: @future async method coverage
    // -------------------------------------------------
    @IsTest
    static void testFutureMethod() {
        Opportunity opp = createTestOpportunity();
        Test.setMock(HttpCalloutMock.class, new YardiMockSuccess());

        Test.startTest();
        RETL_LeadSyncToYardi.pushToYardiAsync(opp.Id);
        Test.stopTest();

        Opportunity updated = [SELECT RETL_Yardi_Id__c FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals('cp05509', updated.RETL_Yardi_Id__c);
    }

    // Attachment
    @IsTest
    static void testAttachmentAndContactProcessing() {
        // Create Opportunity and related data
        Opportunity opp = createTestOpportunity();

        // Create a Contact under the Account (not 'Aldar Leasing Manager')
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = opp.AccountId,
            Title = 'Leasing Consultant'
        );
        insert c;

        // Create a ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'Brand Profile - Test',
            PathOnClient = 'BrandProfile.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        // Link ContentDocument to Contact
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = c.Id,
            ShareType = 'V'
        );
        insert cdl;

        // Mock successful callout
        Test.setMock(HttpCalloutMock.class, new YardiMockSuccess());

        Test.startTest();
        RETL_LeadSyncToYardi.pushToYardiAndUpdate(opp.Id);
        Test.stopTest();

        // Verify Opportunity updated
        Opportunity updatedOpp = [SELECT RETL_Yardi_Id__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('cp05509', updatedOpp.RETL_Yardi_Id__c);

        // Verify ContentVersion enqueued for async processing
        // This indirectly confirms the branch is hit; since enqueueJob cannot be directly checked, we rely on no exceptions
    }



}