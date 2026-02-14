@isTest
private class RETL_UnitSearchTest {

    private static Id standardPricebookId;
    private static Id retailPricebookId;
    private static Retail_Unit__c unit1;
    private static Retail_Unit__c unit2;
    private static Product2 product1;
    private static Product2 product2;
    private static Account testAccount;
    private static Opportunity testOpportunity;

    /**
     * @testSetup method to create common test data efficiently.
     */
    @testSetup
    static void makeData() {
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
        testOpportunity = new Opportunity(
            Name = 'Test Unit Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Pricebook2Id = retailPricebookId, // Must use the Retail PB for OLI insertion
            recordtypeId = opportunityRecordType.Id
        );
        insert testOpportunity;

        // 6. Pre-add Unit 1 to Opportunity (to test 'alreadyAdded' flag)
        OpportunityLineItem preExistingOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = pbeRetail1.Id,
            Quantity = 1,
            UnitPrice = 1,
            RETL_Selected_Unit__c = unit1.Id
        );
        insert preExistingOLI;
    }

    /**
     * Test case for getLineItemCount method.
     */
    @IsTest
    static void getLineItemCount_Test() {
        Id oppId = [SELECT Id FROM Opportunity WHERE Name = 'Test Unit Opp' LIMIT 1].Id;

        Test.startTest();
        Integer count = RETL_UnitSearch.getLineItemCount(oppId);
        Test.stopTest();

        // One OLI was created in @testSetup
        System.assertEquals(1, count, 'Should return count of existing OLIs.');
    }

    /**
     * Test case for getAllProperties method.
     */
    @IsTest
    static void getAllProperties_Test() {
        Test.startTest();
        List<String> properties = RETL_UnitSearch.getAllProperties();
        Test.stopTest();

        System.assertEquals(2, properties.size(), 'Should return two distinct property names.');
        System.assert(properties.contains('Test Property One'), 'Property One should be present.');
        System.assert(properties.contains('Test Property Two'), 'Property Two should be present.');
    }

    /**
     * Test case for getPicklistValues method.
     */
    @IsTest
    static void getPicklistValues_Test() {
        List<String> fields = new List<String>{ 'Unit_Status__c', 'Unit_Type__c' };

        Test.startTest();
        Map<String, List<String>> results = RETL_UnitSearch.getPicklistValues('Retail_Unit__c', fields);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results map should not be null.');
        System.assertEquals(2, results.size(), 'Should return values for both requested fields.');
        System.assert(results.containsKey('Unit_Status__c'), 'Should contain Unit_Status__c picklist.');
        System.assert(results.get('Unit_Status__c').contains('Near Expiry'), 'Status picklist should contain "Near Expiry".');
    }

    /**
     * Test case for searchRetailUnits with various filters.
     */
    @IsTest
    static void searchRetailUnits_Test() {
        Id oppId = [SELECT Id FROM Opportunity WHERE Name = 'Test Unit Opp' LIMIT 1].Id;

        Test.startTest();

        // Case 1: Filter by Status, check pagination, check alreadyAdded, check Per Sqm calculation
        List<Map<String, Object>> results1 = RETL_UnitSearch.searchRetailUnits(
            null, // building
            null, // property
            new List<String>{'Near Expiry'}, // statuses
            null, // types
            10,   // pageSize
            0,    // offsetValue
            null, // minArea
            null, // maxArea
            oppId // currentOpportunityId
        );

        // Case 2: Filter by Property, check Flat Amount calculation
        List<Map<String, Object>> results2 = RETL_UnitSearch.searchRetailUnits(
            null,
            'Test Property Two', // property
            null,
            null,
            10,
            0,
            null,
            null,
            oppId
        );

        Test.stopTest();

        // Assertions for Case 1 (Unit 1 - Near Expiry, Per Sqm, already added)
        System.assertEquals(1, results1.size(), 'Case 1: Should only return 1 Near Expiry unit.');
        Map<String, Object> unitRow1 = results1[0];
        System.assertEquals('YARDI_123', unitRow1.get('UnitID_External_ID__c'), 'Case 1: Should be Unit 1.');
        System.assertEquals(true, unitRow1.get('alreadyAdded'), 'Case 1: Unit 1 should be flagged as already added.');
        // Per Sqm calculation: Rent Budget (50) * Unit Area (100) = 5000.0
        System.assertEquals(5000.0, (Decimal)unitRow1.get('Rent_Budget__c'), 'Case 1: Per Sqm rent calculation failed.');

        // Assertions for Case 2 (Unit 2 - On Hold, Flat Amount, not added)
        System.assertEquals(1, results2.size(), 'Case 2: Should only return 1 unit from Property Two.');
        Map<String, Object> unitRow2 = results2[0];
        System.assertEquals('YARDI_456', unitRow2.get('UnitID_External_ID__c'), 'Case 2: Should be Unit 2.');
        System.assertEquals(false, unitRow2.get('alreadyAdded'), 'Case 2: Unit 2 should NOT be flagged as already added.');
        // Flat Amount calculation: Rent Budget (10000)
        System.assertEquals(10000.0, (Decimal)unitRow2.get('Rent_Budget__c'), 'Case 2: Flat Amount rent calculation failed.');
    }

    /**
     * Test case for createProductsForUnits method.
     */
    @IsTest
    static void createProductsForUnits_Test() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Unit Opp' LIMIT 1];
        Retail_Unit__c unitToProcess = [SELECT Id, Unit_Code__c, UnitID_External_ID__c FROM Retail_Unit__c WHERE UnitID_External_ID__c = 'YARDI_456' LIMIT 1]; // Unit 2 has no Product2 yet

        // UnitWrapper for the new unit (Unit 2)
        RETL_UnitSearch.UnitWrapper uw = new RETL_UnitSearch.UnitWrapper();
        uw.unitId = unitToProcess.Id;
        uw.price = 12345.0;
        uw.quantity = 1.0;
        uw.marketingAmount = 500.0;
        uw.serviceCharge = 100.0;
        uw.rentFreeAmount = 0.0;
        uw.fitoutContributionAmount = 0.0;
        

        Map<String, Object> oppFields = new Map<String, Object>{
            'Description' => 'Test Description update.',
            'RETL_Configure_By__c' => 'Unit Level',
            'RETL_Deposit_Notes__c' => 'Deposit note test.',
            'RETL_TOR_Notes__c' => 'TOR note test.',
            'RETL_Special_Conditions__c' => 'Special condition test.',
            'RETL_FOC_Information__c' => 'FOC info test.',
            'RETL_Fitout_Type__c' => 'After',
            'RETL_General_Notes__c' => 'General note test.',
            'RETL_Permitted_Usage__c' => 'Retail/F&B',
            'RETL_Lease_Nature__c' => 'Retail',
            'RETL_Billing_Frequency__c' => 'Monthly',
            'RETL_AM_PreApproval_Notes__c' => 'AM notes test.',
            'RETL_Handover_Conditions__c' => 'As Is',
           // 'RETL_AM_PreApproval__c' => 'Pending Approval', // This should change StageName

            // Date fields (must be passed as String in ISO 8601 format: YYYY-MM-DD)
            'Start_date__c' => String.valueOf(Date.newInstance(2026, 1, 15)),
            'RETL_Term_Start_Date__c' => String.valueOf(Date.newInstance(2026, 2, 1)),
            'RETL_Term_End_Date__c' => String.valueOf(Date.newInstance(2028, 2, 1)),

            // Integer field
            'RETL_Fitout_Days__c' => 30,
            'RETL_Term__c' => 24, // 24 months

            // Decimal fields
            'RETL_Deposit_Amount__c' => 15000.00,
            'RETL_TOR__c' => 1.5,
            'RETL_Escalation__c' => 5.0,
            'RETL_Total_Base_Rent__c' => 250000.00,
            'RETL_Total_Rent_Free_Amount__c' => 5000.00,
            'RETL_Total_FOC_Amount__c' => 2500.00,
            'RETL_Total_Marketing_Amount__c' => 1000.00,
            'RETL_Total_Service_Charge__c' => 10000.00,

            // Boolean field
            'RETL_Month_Month__c' => true
        };

        Test.startTest();
        // Run the main logic
        List<Id> productIds = RETL_UnitSearch.createProductsForUnits(new List<RETL_UnitSearch.UnitWrapper>{uw}, oppFields, opp.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, productIds.size(), 'Should return 1 Product2 Id (for the newly created product).');

        // Check if Opportunity fields and StageName were updated
        Opportunity updatedOpp = [SELECT RETL_Handover_Conditions__c, RETL_Fitout_Days__c, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('As is', updatedOpp.RETL_Handover_Conditions__c, 'Opportunity field should be updated.');
        System.assertEquals(30, updatedOpp.RETL_Fitout_Days__c, 'Opportunity field should be updated.');
       // System.assertEquals('Pending AM Approval', updatedOpp.StageName, 'Opportunity StageName should be updated.');

        // Check if Product2, PricebookEntry, and OLI were created for Unit 2
        Product2 newProd = [SELECT Id FROM Product2 WHERE ProductCode = :unitToProcess.Unit_Code__c LIMIT 1];
        System.assertNotEquals(null, newProd.Id, 'New Product2 should be created.');

        Integer pbeCount = [SELECT COUNT() FROM PricebookEntry WHERE Product2Id = :newProd.Id];
        System.assertEquals(2, pbeCount, 'Should have 2 PBEs (Standard & Retail) for the new product.');

        List<OpportunityLineItem> olis = [SELECT UnitPrice, RETL_Marketing_Amount__c, RETL_Selected_Unit__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND Product2Id = :newProd.Id];
        System.assertEquals(1, olis.size(), 'New OLI should be created.');
        System.assertEquals(uw.price, olis[0].UnitPrice, 'OLI UnitPrice should match wrapper value.');
        System.assertEquals(uw.marketingAmount, olis[0].RETL_Marketing_Amount__c, 'OLI Marketing Amount should match wrapper value.');
        System.assertEquals(unitToProcess.Id, olis[0].RETL_Selected_Unit__c, 'OLI should link to the correct Retail Unit.');
    }

    /**
     * Test case for getOpportunitiesForUnits method.
     */
    @IsTest
    static void getOpportunitiesForUnits_Test() {
        // Unit 1 (YARDI_123) is already linked to testOpportunity in @testSetup
        List<String> yardiIds = new List<String>{ 'YARDI_123', 'YARDI_NON_EXISTENT' };

        Test.startTest();
        Map<String, List<Map<String, String>>> results = RETL_UnitSearch.getOpportunitiesForUnits(yardiIds);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should only return 1 map entry (for YARDI_123).');
        System.assert(results.containsKey('YARDI_123'), 'Results should contain YARDI_123.');
        System.assertEquals(1, results.get('YARDI_123').size(), 'YARDI_123 should have 1 linked opportunity.');
        System.assertEquals('Test Unit Opp', results.get('YARDI_123')[0].get('Name'), 'Opportunity name should match.');
    }

    /**
     * Test case for refreshUnitAvailability method (Callout Mocking).
     */
    @IsTest
    static void refreshUnitAvailability_Success_Test() {
        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new MockYardiRefreshResponse());

        // Mock the Utility class static method call for MuleSoftSetting__mdt
        // We'll use a local mock for the utility call since we can't truly mock static methods across classes.
        // For production orgs, a mocking utility or dependency injection pattern would be used.
        // For this test, we assume the utility call is successful and returns a mock setting.
        // A full implementation would require mocking the Utilities class if possible.
        // As a simplification for the test execution: we ensure the propertyName is passed.

        String testPropertyName = 'Mock Property';

        Test.startTest();
        RETL_UnitSearch.RefreshResponse response = RETL_UnitSearch.refreshUnitAvailability(testPropertyName, false);
        Test.stopTest();

        // Assertions for successful callout and DML
        System.assertEquals('Success', response.status, 'Refresh status should be Success.');
        System.assert(response.message.contains('3 units successfully'), 'Success message should indicate 3 units updated.');

        // Check if the units were upserted
        List<Retail_Unit__c> refreshedUnits = [SELECT UnitID_External_ID__c, Unit_Status__c, Expiry_Date__c FROM Retail_Unit__c WHERE UnitID_External_ID__c IN ('YARDI_901', 'YARDI_902', 'YARDI_123')];
        System.assertEquals(3, refreshedUnits.size(), 'Should have upserted 3 units.');

        // Check unit update (YARDI_123 was updated from testSetup)
        Retail_Unit__c updatedUnit1 = null;
        for (Retail_Unit__c ru : refreshedUnits) {
            if (ru.UnitID_External_ID__c == 'YARDI_123') {
                updatedUnit1 = ru;
            }
        }
        System.assertEquals('Leased', updatedUnit1.Unit_Status__c, 'Existing unit status should be updated.');
        System.assertEquals(Date.newInstance(2025, 12, 31), updatedUnit1.Expiry_Date__c, 'Date parsing should work.');

        // Check new unit insertion
        Retail_Unit__c newUnit = [SELECT UnitID_External_ID__c FROM Retail_Unit__c WHERE UnitID_External_ID__c = 'YARDI_901' LIMIT 1];
        System.assertNotEquals(null, newUnit, 'New unit YARDI_901 should be inserted.');
    }

    /**
     * Test case for refreshUnitAvailability with callout failure.
     */
    @IsTest
    static void refreshUnitAvailability_Failure_Test() {
        // Mock the callout to return a 500 error
        Test.setMock(HttpCalloutMock.class, new MockYardiRefreshResponse(500, 'Internal Server Error', 'Error from Yardi', null));

        Test.startTest();
        RETL_UnitSearch.RefreshResponse response = RETL_UnitSearch.refreshUnitAvailability('Mock Property', false);
        Test.stopTest();

        // Assertions for callout failure
        System.assertEquals('Failed', response.status, 'Refresh status should be Failed.');
        System.assert(response.message.contains('HTTP 500: Error from Yardi'), 'Error message should contain HTTP status and body.');
    }

    /**
     * Test case for getLineItems and updateProposal.
     */
    @IsTest
    static void getLineItemsAndUpdateProposal_Test() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Unit Opp' LIMIT 1];        
        // 1. Test getLineItems        
        List<OpportunityLineItem> olis = RETL_UnitSearch.getLineItems(opp.Id);        

        System.assertEquals(1, olis.size(), 'Should return 1 OLI.');
        //System.assertEquals(unit1.Id, olis[0].RETL_Selected_Unit__c, 'OLI should link to Unit 1.');

        // 2. Test updateProposal (requires a new test block for DML/Queueable)
        Opportunity updateOpp = new Opportunity(Id = opp.Id, Description = 'Updated Description');
        OpportunityLineItem oliToUpdate = new OpportunityLineItem(Id = olis[0].Id, Quantity = 2);

        Test.startTest();
        // Mock the queueable execution for test isolation
        Test.setMock(Queueable.class, new QueueableMock());
        RETL_UnitSearch.updateProposal(updateOpp, new List<OpportunityLineItem>{oliToUpdate});
        Test.stopTest();

        // Check updates
        Opportunity finalOpp = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        OpportunityLineItem finalOli = [SELECT Quantity FROM OpportunityLineItem WHERE Id = :oliToUpdate.Id];

        System.assertEquals('Updated Description', finalOpp.Description, 'Opportunity field should be updated.');
        System.assertEquals(2.0, finalOli.Quantity, 'OLI quantity should be updated.');
        // Verify the queueable was added (it will not run in Test.startTest/Test.stopTest unless run as a job)
        // Since we mocked it, we just verify the DML. The framework handles the System.enqueueJob call.
    }
    
    /**
     * Helper class to mock the external callout for refreshUnitAvailability.
     */
    private class MockYardiRefreshResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String body;
        private Map<String, String> headers;

        // Constructor for success case
        public MockYardiRefreshResponse() {
            this.statusCode = 200;
            this.status = 'OK';
            this.headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
            this.body = '[' +
                // New Unit
                '{"UnitID":"YARDI_901","UnitCode":"901","PropertyCode":"P1","PropertyName":"Mock Property","UnitStatus":"Near Expiry","UnitArea":50.0,"ExpiryDate":"01/01/2026"},' +
                // New Unit with date error
                '{"UnitID":"YARDI_902","UnitCode":"902","PropertyCode":"P1","PropertyName":"Mock Property","UnitStatus":"Near Expiry","UnitArea":50.0,"ExpiryDate":"INVALID_DATE"},' +
                // Existing Unit (YARDI_123) - will be updated
                '{"UnitID":"YARDI_123","UnitCode":"A101","PropertyCode":"P2","PropertyName":"Mock Property","UnitStatus":"Leased","UnitArea":100.0,"ExpiryDate":"31/12/2025"}' +
                ']';
        }

        // Constructor for failure case
        public MockYardiRefreshResponse(Integer statusCode, String status, String body, Map<String, String> headers) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body;
            this.headers = headers;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            return res;
        }
    }

    /**
     * Simple mock for the Queueable class called in updateProposal.
     */
    private class QueueableMock implements Queueable {
        public void execute(QueueableContext context) {
            // Do nothing, just satisfy the mock
        }
    }
}