@isTest
private class RETL_UnitSyncToYardiQueueableTest {

    private static Id standardPricebookId;
    private static Id retailPricebookId;
    private static Retail_Unit__c unit1, unit2;
    private static Product2 product1;
    private static Account testAccount;

    // -------------------------
    // Mock Callout Class
    // -------------------------
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean isError;

        public MockHttpResponseGenerator() {
            this.statusCode = 200;
            this.responseBody = '{"Status":"Success","Message":"Lead Unit synced.","Details":[{"CustomTableRecordCode":"YARDI-REC-123"}]}';
            this.isError = false;
        }

        public MockHttpResponseGenerator(Integer status, String body, Boolean error) {
            this.statusCode = status;
            this.responseBody = body;
            this.isError = error;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            res.setStatus(isError ? 'Error' : 'OK');
            return res;
        }
    }

    // -------------------------
    // Test Setup
    // -------------------------
    @TestSetup
    static void setupTestData() {

        // 1. Pricebooks
        standardPricebookId = Test.getStandardPricebookId();
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
            Rent_Budget__c = 50.0,
            Net_Service_Charge_Budget__c = 10.0,
            Amount_Type__c = 'Per Sqm'
        );
        unit2 = new Retail_Unit__c(
            Unit_Code__c = 'B202',
            UnitID_External_ID__c = 'YARDI_456',
            Property_Name__c = 'Test Property Two',
            Unit_Status__c = 'On Hold',
            Unit_Type__c = 'Retail Shop',
            Unit_Area__c = 250.0,
            Rent_Budget__c = 10000.0,
            Net_Service_Charge_Budget__c = 2000.0,
            Amount_Type__c = 'Flat Amount'
        );
        insert new List<Retail_Unit__c>{unit1, unit2};

        // 3. Product for Unit1
        product1 = new Product2(
            Name = unit1.Unit_Code__c,
            ProductCode = unit1.Unit_Code__c,
            RETL_Yardi_Id__c = unit1.UnitID_External_ID__c,
            IsActive = true
        );
        insert product1;

        // 4. Pricebook Entries
        PricebookEntry pbeStd1 = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product1.Id,
            UnitPrice = 0,
            IsActive = true,
            RETL_External_ID__c = standardPricebookId + '-' + product1.RETL_Yardi_Id__c
        );
        PricebookEntry pbeRetail1 = new PricebookEntry(
            Pricebook2Id = retailPricebookId,
            Product2Id = product1.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbeStd1, pbeRetail1};

        // 5. Account
        testAccount = new Account(Name = 'Test Account for Units');
        insert testAccount;

        // Opportunity RecordType
        RecordType opportunityRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'RETL_Opportunity' AND SObjectType = 'Opportunity' LIMIT 1];

        // 6. Opportunity (Unit Level)
        Opportunity oppUnitLevel = new Opportunity(
            Name = 'Test Opp Unit Level',
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
            Pricebook2Id = retailPricebookId,
            RecordTypeId = opportunityRecordType.Id
        );
        insert oppUnitLevel;

        // Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppUnitLevel.Id,
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

        // 7. Opportunity (Deal Level)
        Opportunity oppDealLevel = new Opportunity(
            Name = 'Test Opp Deal Level',
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
            Pricebook2Id = retailPricebookId,
            RecordTypeId = opportunityRecordType.Id
        );
        insert oppDealLevel;

        // OLI for Deal Level
        OpportunityLineItem oliDeal = new OpportunityLineItem(
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
        insert oliDeal;
    }

    // -------------------------
    // Test: Successful Callout
    // -------------------------
    @IsTest
    static void test_pushLeadUnitToYardi_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE RETL_Configure_By__c='Unit Level' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new RETL_UnitSyncToYardiQueueable(opp.Id));
        Test.stopTest();

        // Verify Opportunity updated with Yardi record code
        Opportunity updatedOpp = [SELECT RETL_Lead_Financial_Yardi_Id__c, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('YARDI-REC-123', updatedOpp.RETL_Lead_Financial_Yardi_Id__c);
        System.assertEquals('Submitted for Proposal', updatedOpp.StageName);
    }

    // -------------------------
    // Test: Payload Structure
    // -------------------------
    @IsTest
    static void test_buildLeadUnitWrapper_Structure() {
        Opportunity opp = [SELECT Id,RETL_Yardi_Id__c FROM Opportunity WHERE RETL_Configure_By__c='Unit Level' LIMIT 1];

        RETL_YardiCustomTableWrapper.CustomTableRequest wrapper =
            RETL_UnitSyncToYardiQueueable.buildLeadUnitWrapper(opp.Id, 'COMMPROSPECTBUT_LEAD_CHRG');

        System.assert(wrapper != null, 'Payload should not be null');
        System.assert(wrapper.Description.contains('Lead Financial Info'), 'Description is correct');
        System.assertNotEquals(null, wrapper.RequestId, 'RequestId is set');
        System.assertEquals(1, wrapper.Details.size(), 'One table in Details');

        RETL_YardiCustomTableWrapper.TableWrapper table = wrapper.Details[0];
        System.assertEquals('COMMPROSPECTBUT_LEAD_CHRG', table.TableName);
        System.assertEquals(1, table.Data.size(), 'One record in table');

        RETL_YardiCustomTableWrapper.RecordWrapper rec = table.Data[0];
        System.assertEquals(opp.RETL_Yardi_Id__c, rec.EntityRecordCode);
        System.assert(rec.Fields.size() > 0, 'Fields should be populated');
    }
}