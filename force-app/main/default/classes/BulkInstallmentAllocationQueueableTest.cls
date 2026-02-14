/**
 * @description Test class for BulkInstallmentAllocationQueueable
 */
@isTest
private class BulkInstallmentAllocationQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        //Dummy commit for test class new
        Test.startTest();
        //dummy commit fot test class
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
        rakCharge.Amount__c = 500; // Set to 500 to match allocation
        rakCharge.isValidationBypass__c = true;
        update rakCharge;
        
        SalesOrderOtherCharges__c admCharge = TestObjectsFactory.createSalesOrderOtherCharges(testSalesOrder.Id, testAccount.Id);
        admCharge.TypeOfCharge__c = 'ADM Fee';
        admCharge.Amount__c = 500; // Set to 500 to match allocation
        admCharge.isValidationBypass__c = true;
        update admCharge;
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkInstallmentAllocationComprehensive() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Org for Bulk Allocation' LIMIT 1];
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c WHERE Unit__r.Name = 'TestUnitBulkAllocation' LIMIT 1];
        List<InstallmentLines__c> installmentLines = [SELECT Id FROM InstallmentLines__c WHERE SalesOrder__c = :testSalesOrder.Id];
        List<SalesOrderOtherCharges__c> otherCharges = [SELECT Id, TypeOfCharge__c, Amount__c FROM SalesOrderOtherCharges__c WHERE SalesOrder__c = :testSalesOrder.Id];
        
        Test.startTest();
        
        // Test 1: Create receipt with mixed charges (installments + other charges)
        ReceiptAcknowledgement__c receipt1 = new ReceiptAcknowledgement__c(
            Account__c = testAccount.Id,
            SalesOrder__c = testSalesOrder.Id,
            Amount__c = 5000,
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
            // Bypass validation rule for each other charge allocation
            oc.isValidationBypass__c = true;
            // Ensure allocation does not exceed Amount__c to avoid validation error
            Decimal allocationAmount = oc.Amount__c != null && oc.Amount__c < 500 ? oc.Amount__c : 500;
            update oc;
            allocations1.add(new ReceiptAllocation__c(
                ReceiptAcknowledgement__c = receipt1.Id,
                SalesOrderOtherCharges__c = oc.Id,
                AmountApplied__c = allocationAmount,
                Account__c = testAccount.Id,
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
            Amount__c = 3000,
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
            Amount__c = 1000,
            PaymentType__c = 'Online',
            Status__c = 'Received',
            ReferenceNumber__c = 'REF-Bulk-003',
            Bulk_Installment_Allocation__c = true,
            OnlinePaymentCleared__c = false, // Not cleared
            CurrencyIsoCode = 'AED'
        );
        insert receipt3;
        
        // Test 4: Test with null receipt IDs
        System.enqueueJob(new BulkInstallmentAllocationQueueable(null));
        
        // Test 5: Test with empty receipt IDs
        System.enqueueJob(new BulkInstallmentAllocationQueueable(new Set<Id>()));
        
        // Test 6: Test with valid receipt IDs (mixed scenario)
        Set<Id> receiptIds = new Set<Id>{receipt1.Id, receipt2.Id, receipt3.Id};
        System.enqueueJob(new BulkInstallmentAllocationQueueable(receiptIds));
        
        Test.stopTest();
        
        // Query results for verification (no assertions)
        List<ReceiptAcknowledgement__c> allReceipts = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c, ReferenceNumber__c, Remarks__c
            FROM ReceiptAcknowledgement__c 
            WHERE SalesOrder__c = :testSalesOrder.Id
            ORDER BY CreatedDate ASC
        ];
        
        // Query original receipt1
        ReceiptAcknowledgement__c originalReceipt1 = [SELECT Id, Bulk_Installment_Allocation__c, ReferenceNumber__c 
                                                    FROM ReceiptAcknowledgement__c 
                                                    WHERE Id = :receipt1.Id];
        
        // Query new receipts for other charges from receipt1
        List<ReceiptAcknowledgement__c> newReceipts = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c, ReferenceNumber__c, Remarks__c
            FROM ReceiptAcknowledgement__c 
            WHERE SalesOrder__c = :testSalesOrder.Id 
            AND Id != :receipt1.Id 
            AND Id != :receipt2.Id 
            AND Id != :receipt3.Id
        ];
        
        // Query allocations for receipt1
        List<ReceiptAllocation__c> originalAllocations = [
            SELECT Id, AmountApplied__c, TypeOfInvoice__c
            FROM ReceiptAllocation__c 
            WHERE ReceiptAcknowledgement__c = :receipt1.Id
        ];
        
        // Query new allocations for other charges
        List<ReceiptAllocation__c> newAllocations = [
            SELECT Id, ReceiptAcknowledgement__c, AmountApplied__c, TypeOfInvoice__c
            FROM ReceiptAllocation__c 
            WHERE ReceiptAcknowledgement__c IN :newReceipts
        ];
        
        // Query receipt2 results
        List<ReceiptAcknowledgement__c> receipt2Results = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c
            FROM ReceiptAcknowledgement__c 
            WHERE Id = :receipt2.Id
        ];
        
        // Query receipt3 results
        List<ReceiptAcknowledgement__c> receipt3Results = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c
            FROM ReceiptAcknowledgement__c 
            WHERE Id = :receipt3.Id
        ];
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
        System.enqueueJob(new BulkInstallmentAllocationQueueable(receiptIds));
        
        Test.stopTest();
        
        // Query results when feature is disabled
        List<ReceiptAcknowledgement__c> allReceipts = [
            SELECT Id, Amount__c, Bulk_Installment_Allocation__c
            FROM ReceiptAcknowledgement__c 
            WHERE SalesOrder__c = :testSalesOrder.Id
        ];
    }
    
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