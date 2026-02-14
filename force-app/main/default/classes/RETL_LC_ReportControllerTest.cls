@IsTest
public class RETL_LC_ReportControllerTest {

    /* -----------------------
       Test Data Setup
       ----------------------- */
    @TestSetup
    static void setupData() {

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 100000,
            AccountId = acc.Id
        );
        insert opp;

        // Product
        Product2 prod = new Product2(
            Name = 'Unit A',
            Family = 'Retail',
            IsActive = true
        );
        insert prod;

        // Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;

     

        // Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
          
        );
        insert oli;

        // Leasing Committee Template
        RETL_Leasing_Committee_Data__c template = new RETL_Leasing_Committee_Data__c(
            Name = 'Template 1',
            Template_Data__c = '{"key":"value"}',
            Opportunity__c = opp.Id
        );
        insert template;

        // Order (Benchmark Lease)
        Order ord = new Order(
            Name = 'Benchmark Lease',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
    }

    /* -----------------------
       saveCommitteeData
       ----------------------- */
    @IsTest
    static void testSaveCommitteeDataSuccess() {
        RETL_Leasing_Committee_Data__c rec =
            [SELECT Id FROM RETL_Leasing_Committee_Data__c LIMIT 1];

        Test.startTest();
        RETL_LeasingCommitteeReportController.saveCommitteeData(
            rec.Id,
            '{"updated":"true"}'
        );
        Test.stopTest();

        RETL_Leasing_Committee_Data__c updated =
            [SELECT Template_Data__c FROM RETL_Leasing_Committee_Data__c WHERE Id = :rec.Id];

        System.assertEquals('{"updated":"true"}', updated.Template_Data__c);
    }

    @IsTest
    static void testSaveCommitteeDataValidationError() {
        Test.startTest();
        try {
            RETL_LeasingCommitteeReportController.saveCommitteeData(null, '{"x":"y"}');
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Template ID is required'));
        }
        Test.stopTest();
    }

    /* -----------------------
       fetchCommitteeData
       ----------------------- */
    @IsTest
    static void testFetchCommitteeDataSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        String data =
            RETL_LeasingCommitteeReportController.fetchCommitteeData(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, data);
    }

    @IsTest
    static void testFetchCommitteeDataNoRecord() {
        Test.startTest();
        String data =
            RETL_LeasingCommitteeReportController.fetchCommitteeData(null);
        Test.stopTest();

        System.assertEquals(null, data);
    }

    /* -----------------------
       getOppLineData
       ----------------------- */
@IsTest
static void testGetOppLineData_WithRetailUnit() {

    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = acc.Id
    );
    insert opp;

    Product2 prod = new Product2(
        Name = 'Unit A',
        IsActive = true
    );
    insert prod;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 1000,
        IsActive = true
    );
    insert pbe;

    // 🔑 Retail Unit
    Retail_Unit__c unit = new Retail_Unit__c(
       // Name = 'Retail Unit 1',
        Unit_Area__c = 150,
        Floor__c = 'First'
    );
    insert unit;

    OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 1000,
        RETL_Selected_Unit__c = unit.Id
    );
    insert oli;

    Test.startTest();
    RETL_LeasingCommitteeReportController.OppLineWrapper wrapper =
        RETL_LeasingCommitteeReportController.getOppLineData(opp.Id);
    Test.stopTest();

    System.assertNotEquals(null, wrapper);
    System.assert(wrapper.unitNames.contains('Unit A'));
    System.assertEquals(150, wrapper.GLA);
    System.assertEquals('First', wrapper.floor);
    System.assertEquals(1, wrapper.lines.size());
}

    /* -----------------------
       saveTemplateData
       ----------------------- */
    @IsTest
    static void testSaveTemplateData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        RETL_LeasingCommitteeReportController.saveTemplateData(
            'New Template',
            '{"json":"data"}',
            opp.Id
        );
        Test.stopTest();

        Integer countTemplates = [
            SELECT COUNT()
            FROM RETL_Leasing_Committee_Data__c
            WHERE Name = 'New Template'
        ];

        System.assertEquals(1, countTemplates);
    }

    /* -----------------------
       getSavedTemplates
       ----------------------- */
    @IsTest
    static void testGetSavedTemplates() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<RETL_LeasingCommitteeReportController.TemplateWrapper> templates =
            RETL_LeasingCommitteeReportController.getSavedTemplates(opp.Id);
        Test.stopTest();

        System.assert(templates.size() > 0);
        System.assertNotEquals(null, templates[0].templateId);
    }

    /* -----------------------
       fetchTemplateData
       ----------------------- */
    @IsTest
    static void testFetchTemplateData() {
        RETL_Leasing_Committee_Data__c rec =
            [SELECT Id FROM RETL_Leasing_Committee_Data__c LIMIT 1];

        Test.startTest();
        String data =
            RETL_LeasingCommitteeReportController.fetchTemplateData(rec.Id);
        Test.stopTest();

        System.assertNotEquals(null, data);
    }

    /* -----------------------
       getBenchmarkLeases
       ----------------------- */
    @IsTest
    static void testGetBenchmarkLeases() {
        Test.startTest();
        List<Order> orders =
            RETL_LeasingCommitteeReportController.getBenchmarkLeases();
        Test.stopTest();

        System.assert(orders.size() > 0);
        System.assertNotEquals(null, orders[0].AccountId);
    }
}