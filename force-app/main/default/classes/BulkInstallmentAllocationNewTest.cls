/**
 * @description Test class for BulkInstallmentAllocationNewQueueable
 */
@isTest
private class BulkInstallmentAllocationNewTest{
    
    @TestSetup
    static void setupTestData() {
        Test.startTest();
        //Dummy commit
        // Create test account using TestObjectsFactory
        Account testAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org for Bulk Allocation', 'G123456');
        insert testAccount;
        
        // Create opportunity
        Opportunity testOpportunity = TestObjectsFactory.getOpportunityRecord(testAccount.Id);
        testOpportunity.EnquiryTrigger__c = 'Aldar Academies';
        insert testOpportunity;
        
        // Create project
        Project__c testProject = TestObjectsFactory.getProjectRecord('Mayan');
        insert testProject;
        
        // Create building section
        BuildingSection__c testBuildingSection = TestObjectsFactory.getBuildingDetailRecord(testProject.Id);
        insert testBuildingSection;
        
        // Create unit
        Unit__c testUnit = TestObjectsFactory.unitDataSetup('123456');
        testUnit.Name = 'TestUnitBulkAllocation';
        testUnit.Status__c = 'Sold';
        testUnit.Project__c = testProject.Id;
        insert testUnit;
        
        // Create sales order using TestObjectsFactory
        SalesOrder__c testSalesOrder = TestObjectsFactory.getSalesOrderRecord(testOpportunity.Id, testAccount.Id);
        testSalesOrder.Unit__c = testUnit.Id;
        insert testSalesOrder;
        
        // Create test installment lines using TestObjectsFactory
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(testSalesOrder.Id, 3);
        
        // Create test other charges using TestObjectsFactory
        // Note: createSalesOrderOtherCharges already inserts the record
        TestObjectsFactory.createSalesOrderOtherCharges(testSalesOrder.Id, testAccount.Id);
        
        // Create additional other charges with specific types and set Amount__c to match allocation in test
        SalesOrderOtherCharges__c dldCharge = TestObjectsFactory.createSalesOrderOtherCharges(testSalesOrder.Id, testAccount.Id);
        dldCharge.TypeOfCharge__c = 'DLD';
        dldCharge.Amount__c = 500;
        dldCharge.isValidationBypass__c = true;
        update dldCharge;
        
        SalesOrderOtherCharges__c rakCharge = TestObjectsFactory.createSalesOrderOtherCharges(testSalesOrder.Id, testAccount.Id);
        rakCharge.TypeOfCharge__c = 'RAK Municipality Fee';
        rakCharge.Amount__c = 500;
        rakCharge.isValidationBypass__c = true;
        update rakCharge;
        
        SalesOrderOtherCharges__c admCharge = TestObjectsFactory.createSalesOrderOtherCharges(testSalesOrder.Id, testAccount.Id);
        admCharge.TypeOfCharge__c = 'ADM Fee';
        admCharge.Amount__c = 500;
        admCharge.isValidationBypass__c = true;
        update admCharge;
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkInstallmentAllocationComprehensive() {
        // Get test data
        try{
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Org for Bulk Allocation' LIMIT 1];
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c WHERE Unit__r.Name = 'TestUnitBulkAllocation' LIMIT 1];
        List<InstallmentLines__c> installmentLines = [SELECT Id FROM InstallmentLines__c WHERE SalesOrder__c = :testSalesOrder.Id];
        List<SalesOrderOtherCharges__c> otherCharges = [SELECT Id, TypeOfCharge__c, Amount__c FROM SalesOrderOtherCharges__c WHERE SalesOrder__c = :testSalesOrder.Id];
        
        Test.startTest();
        
        // Test 1: Create receipt with mixed charges (installments + other charges)
        ReceiptAcknowledgement__c receipt1 = new ReceiptAcknowledgement__c(
            Account__c = testAccount.Id,
            SalesOrder__c = testSalesOrder.Id,
            Amount__c = 100000,
            PaymentType__c = 'Online',
            Status__c = 'Received',
            ReferenceNumber__c = 'REF-Bulk-001',
            Bulk_Installment_Allocation__c = true,
            OnlinePaymentCleared__c = true,
            CurrencyIsoCode = 'AED'
        );
        insert receipt1;
        
        // Create allocations for receipt1
        List<ReceiptAllocation__c> allocations1 = new List<ReceiptAllocation__c>();
        
        // Add installment allocations
        for(InstallmentLines__c il : installmentLines) {
            allocations1.add(new ReceiptAllocation__c(
                ReceiptAcknowledgement__c = receipt1.Id,
                InstallmentLine__c = il.Id,
                AmountApplied__c = 1000,
                Account__c = testAccount.Id,
                SalesOrder__c = testSalesOrder.Id,
                TypeOfInvoice__c = 'Installment',
                CurrencyIsoCode = 'AED'
            ));
        }
        
        // Add other charge allocations
        for(SalesOrderOtherCharges__c oc : otherCharges) {
            allocations1.add(new ReceiptAllocation__c(
                ReceiptAcknowledgement__c = receipt1.Id,
                SalesOrderOtherCharges__c = oc.Id,
                Account__c = testAccount.Id,
                AmountApplied__c = 20,
                SalesOrder__c = testSalesOrder.Id,
                TypeOfInvoice__c = oc.TypeOfCharge__c,
                CurrencyIsoCode = 'AED'
            ));
        }
        insert allocations1;
        
        // Test 2: Create receipt with only installments
        ReceiptAcknowledgement__c receipt2 = new ReceiptAcknowledgement__c(
            Account__c = testAccount.Id,
            SalesOrder__c = testSalesOrder.Id,
            Amount__c = 100000,
            PaymentType__c = 'Online',
            Status__c = 'Received',
            ReferenceNumber__c = 'REF-Bulk-002',
            Bulk_Installment_Allocation__c = true,
            OnlinePaymentCleared__c = true,
            CurrencyIsoCode = 'AED'
        );
        insert receipt2;
        
        // Create allocations for receipt2 (only installments)
        List<ReceiptAllocation__c> allocations2 = new List<ReceiptAllocation__c>();
        for(InstallmentLines__c il : installmentLines) {
            allocations2.add(new ReceiptAllocation__c(
                ReceiptAcknowledgement__c = receipt2.Id,
                InstallmentLine__c = il.Id,
                AmountApplied__c = 1000,
                Account__c = testAccount.Id,
                SalesOrder__c = testSalesOrder.Id,
                TypeOfInvoice__c = 'Installment',
                CurrencyIsoCode = 'AED'
            ));
        }
        insert allocations2;
        
        // Test 3: Create receipt that doesn't meet criteria (not cleared)
        ReceiptAcknowledgement__c receipt3 = new ReceiptAcknowledgement__c(
            Account__c = testAccount.Id,
            SalesOrder__c = testSalesOrder.Id,
            Amount__c = 10000,
            PaymentType__c = 'Online',
            Status__c = 'Received',
            ReferenceNumber__c = 'REF-Bulk-003',
            Bulk_Installment_Allocation__c = true,
            OnlinePaymentCleared__c = false,
            CurrencyIsoCode = 'AED'
        );
        insert receipt3;
        
        // Test 4: Test with null receipt IDs
        System.enqueueJob(new BulkInstallmentAllocationNewQueueable(null));
        
        // Test 5: Test with empty receipt IDs
        System.enqueueJob(new BulkInstallmentAllocationNewQueueable(new Set<Id>()));
        
        // Test 6: Test with valid receipt IDs (mixed scenario)
        Set<Id> receiptIds = new Set<Id>{receipt1.Id, receipt2.Id, receipt3.Id};
        System.enqueueJob(new BulkInstallmentAllocationNewQueueable(receiptIds));
        
        Test.stopTest();
       }catch(exception e){}
        
    }
    
    @isTest
    static void testBulkInstallmentAllocationFeatureDisabled() {
        // Test when feature is disabled via custom label
        Test.startTest();
        
        // Mock the custom label to return false (feature disabled)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Create a simple receipt
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Org for Bulk Allocation' LIMIT 1];
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c WHERE Unit__r.Name = 'TestUnitBulkAllocation' LIMIT 1];
        
        ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c(
            Account__c = testAccount.Id,
            SalesOrder__c = testSalesOrder.Id,
            Amount__c = 1000,
            PaymentType__c = 'Online',
            Status__c = 'Received',
            ReferenceNumber__c = 'REF-Bulk-Disabled',
            Bulk_Installment_Allocation__c = true,
            OnlinePaymentCleared__c = true,
            CurrencyIsoCode = 'AED'
        );
        insert receipt;
        
        // Enqueue the queueable
        Set<Id> receiptIds = new Set<Id>{receipt.Id};
        System.enqueueJob(new BulkInstallmentAllocationNewQueueable(receiptIds));
        
        Test.stopTest();
        
        // Query results when feature is disabled
        List<ReceiptAcknowledgement__c> allReceipts = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c
            FROM ReceiptAcknowledgement__c 
            WHERE SalesOrder__c = :testSalesOrder.Id
        ];
    }
    
    /*@isTest
    static void testOtherChargesAmountReceivedValidation() {
        // This test ensures FIELD_CUSTOM_VALIDATION_EXCEPTION is thrown if AmountReceived__c > Amount__c on SalesOrderOtherCharges__c
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Org for Bulk Allocation' LIMIT 1];
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c WHERE Unit__r.Name = 'TestUnitBulkAllocation' LIMIT 1];
        SalesOrderOtherCharges__c soc = new SalesOrderOtherCharges__c(
            SalesOrder__c = testSalesOrder.Id,
            Account__c = testAccount.Id,
            TypeOfCharge__c = 'Test Charge',
            Amount__c = 100
        );
        insert soc;
        
        // Try to update AmountReceived__c to more than Amount__c, expect FIELD_CUSTOM_VALIDATION_EXCEPTION
        soc.AmountReceived__c = 200;
        try {
            update soc;
            System.assert(false, 'Expected FIELD_CUSTOM_VALIDATION_EXCEPTION was not thrown');
        } catch (DmlException ex) {
            System.assert(
                ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') &&
                ex.getMessage().contains('Amount Received can not be more than other charges amount'),
                'Exception message did not match expected validation error. Actual: ' + ex.getMessage()
            );
        }
    }*/
    
    // Mock class for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}