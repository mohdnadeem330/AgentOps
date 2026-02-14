@IsTest
private class RETL_DealUpdateToYardiQueueableTest {

    private static Id standardPricebookId;
    private static Id retailPricebookId;
    private static Retail_Unit__c unit1;
    private static Retail_Unit__c unit2;
    private static Product2 product1;
    private static Product2 product2;
    private static Account testAccount;
    private static Opportunity testOpportunity;

    // ---------------------------------------------------------
    // Mock class for MuleSoft callout
    // ---------------------------------------------------------
    private class MuleMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Status":"Success","Message":"OK"}');
            return res;
        }
    }

    private class MuleMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"Status":"Error","Message":"Server Error"}');
            return res;
        }
    }

    // ---------------------------------------------------------
    // Utility to insert MuleSoft Custom Metadata into describe cache
    // ---------------------------------------------------------
    @TestSetup
    static void setupData() {        

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

        //Deal Level

        Opportunity oppDealLevel = new Opportunity(
            Name = 'Test oppDealLevel',
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
            RETL_Configure_By__c = 'Deal Level',
            RETL_Escalation__c = 5,
            RETL_Billing_Frequency__c = 'Monthly',
            RETL_Term_Start_Date__c = Date.today(),
            RETL_Term_End_Date__c = Date.today().addYears(1),
            AccountId = testAccount.Id,
            Pricebook2Id = retailPricebookId, // Must use the Retail PB for OLI insertion
            recordtypeId = opportunityRecordType.Id
        );
        insert oppDealLevel;

        // Insert OLI
        OpportunityLineItem oliDealLevel = new OpportunityLineItem(
            OpportunityId = oppDealLevel.Id,
            Quantity = 1,
            UnitPrice = 1000,
            PricebookEntryId = pbeRetail1.Id,
            RETL_Service_Charge__c = 200,
            RETL_Marketing_Amount__c = 300,
            RETL_Rent_Free_Amount__c = 100,
            RETL_Fitout_Contribution_Amount__c = 50,
            RETL_Selected_Unit__c = unit1.Id
        );
        insert oliDealLevel;
    }

    // ---------------------------------------------------------
    // TEST 1: Validate Payload Builder
    // ---------------------------------------------------------
    @IsTest
    static void testBuildPayload() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        RETL_YardiCustomTableWrapper.CustomTableRequest req =
            RETL_DealUpdateToYardiQueueable.buildDealPayload(opp.Id, 'WOBUT_LEAD_CHRG');
        Test.stopTest();

        System.assertNotEquals(null, req, 'Payload must not be null');
        System.assertEquals('Lead Financial Info Update', req.Description);
        System.assert(req.Details.size() == 1, 'Should have exactly one table wrapper');
        System.assert(req.Details[0].Data.size() == 1, 'Should contain one record wrapper');
    }

    // ---------------------------------------------------------
    // TEST 2: Queueable execution (success callout)
    // ---------------------------------------------------------
    @IsTest
    static void testQueueableSuccess() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MuleMockSuccess());

        Test.startTest();
        System.enqueueJob(new RETL_DealUpdateToYardiQueueable(opp.Id));
        Test.stopTest();

        // No exception means success
        System.assert(true);
    }

    // Deal Level
    @IsTest
    static void testQueueableSuccess_DealLevel() {

        Opportunity oppDealLevel = [SELECT Id FROM Opportunity where RETL_Configure_By__c='Deal Level' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MuleMockSuccess());

        Test.startTest();
        System.enqueueJob(new RETL_DealUpdateToYardiQueueable(oppDealLevel.Id));
        Test.stopTest();

        // No exception means success
        System.assert(true);
    }

    // ---------------------------------------------------------
    // TEST 3: Queueable execution (error callout)
    // ---------------------------------------------------------
    @IsTest
    static void testQueueableError() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MuleMockError());

        Test.startTest();
        System.enqueueJob(new RETL_DealUpdateToYardiQueueable(opp.Id));
        Test.stopTest();

        System.assert(true, 'Queueable should complete without unhandled exception');
    }
}