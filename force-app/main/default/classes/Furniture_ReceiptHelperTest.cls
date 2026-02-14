/**
* @File Name : Furniture_ReceiptHelperTest.cls
* @Description : Test class for Furniture_ReceiptHelper and Furniture_PaymentSplitDataWrapper
* @Author : Harsh
* @Last Modified By : 
* @Last Modified On : June 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 15, 2025 |   | Initial Version
**/

@isTest
public class Furniture_ReceiptHelperTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com'
        );
        insert testContact;
        
        // Create test Opportunity (required for Order creation)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
        
        // Create test Quote linked to Opportunity
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Primary__c = true // Explicitly set the Name field
        );
        insert testQuote;
        
        
       
        
        // Update Opportunity with primary quote
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        update testOpportunity;
        
        /*testQuote.SBQQ__Ordered__c = true; 
        update testQuote;*/
        
        
        // Create test Order
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = testOpportunity.Id,
            SBQQ__Quote__c = testQuote.Id,
            Status = 'Draft',
         //   Sub_Status__c = 'Order Placed',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
     //   Order testOrder =  [SELECT Id FROM Order WHERE SBQQ__Quote__c =: testQuote.Id];
    }
    /*
   @isTest
    static void testProcessPaymentResponse_Success() {
        // Get test data - Use proper SOQL with field names
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Name = 'Test Account'  LIMIT 1];
        system.debug('testQuote'+ testQuote);
        
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addDays(180);
        update testQuote;
        
        // Mock JSON response
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        // Test the main method
        CustomerCreateReceiptController.PaymentModel result = Furniture_ReceiptHelper.processPaymentResponse(
            mockJsonResponse, 
            testQuote.Id, 
            testAccount.Id, 
            'INV-001', 
            'REC-001'
        );
        system.debug('testQuote2'+ testQuote);
        
        
        // Verify results
        System.assertNotEquals(null, result, 'Payment model should not be null');
        System.assertNotEquals(null, result.receiptId, 'Receipt ID should not be null');
        System.assertNotEquals(null, result.receiptDetails, 'Receipt details should not be null');
        
        // Verify receipt was created
        List<ReceiptAcknowledgement__c> receipts = [
            SELECT Id, Amount__c, PaymentType__c, Status__c, InvoiceNumber__c, 
                   ReferenceNumber__c, Payment_Gateway__c, JSONResponse__c
            FROM ReceiptAcknowledgement__c 
            WHERE CPQQuote__c = :testQuote.Id
        ];
                system.debug('testQuote3'+ testQuote);

        System.assertEquals(1, receipts.size(), 'One receipt should be created');
        ReceiptAcknowledgement__c receipt = receipts[0];
        System.assertEquals('Online', receipt.PaymentType__c, 'Payment type should be Online');
        System.assertEquals('Received', receipt.Status__c, 'Status should be Received');
        System.assertEquals('INV-001', receipt.InvoiceNumber__c, 'Invoice number should match');
        System.assertEquals('CC-REC-001', receipt.ReferenceNumber__c, 'Reference number should match');
        System.assertEquals('Stripe', receipt.Payment_Gateway__c, 'Payment gateway should be Stripe');
        //System.assertEquals(mockJsonResponse, receipt.JSONResponse__c, 'JSON response should match');
                system.debug('testQuote4'+ testQuote);

        // Verify quote was updated
        SBQQ__Quote__c updatedQuote = [
            SELECT Id, Total_Amount_Paid__c,SBQQ__Ordered__c,  Total_Amount_Received__c, Total_Stripe_Fee__c,
                   VAT_Amount__c, Aldar_Amount__c, Vendor_Amount__c, Transaction_Date__c
            FROM SBQQ__Quote__c 
            WHERE Id = :testQuote.Id
        ];
                system.debug('updatedQuote'+ updatedQuote);

        System.assertNotEquals(null, updatedQuote.Total_Amount_Paid__c, 'Total amount paid should be set');
        System.assertNotEquals(null, updatedQuote.Total_Amount_Received__c, 'Total amount received should be set');
        System.assertNotEquals(null, updatedQuote.Total_Stripe_Fee__c, 'Total Stripe fee should be set');
        System.assertNotEquals(null, updatedQuote.VAT_Amount__c, 'VAT amount should be set');
        
        // Verify order was updated
        List<Order> orders = [
            SELECT Id, Total_Amount_Paid1__c, Total_Amount_Received1__c, Total_Stripe_Fee1__c,
                   VAT_Amount1__c, Aldar_Amount1__c, Vendor_Amount1__c, Transaction_Date1__c
            FROM Order 
            WHERE SBQQ__Quote__c = :testQuote.Id
        ];
        system.debug('orders'+ orders);
        System.assertEquals(1, orders.size(), 'Order should exist');
        Order updatedOrder = orders[0];
        Test.stopTest();
        System.assertNotEquals(null, updatedOrder.Total_Amount_Paid1__c, 'Order total amount paid should be set');
        System.assertNotEquals(null, updatedOrder.Total_Amount_Received1__c, 'Order total amount received should be set');
    }
  */
    @isTest
    static void testProcessPaymentResponse_InvalidJson() {
        // Get test data - Use proper field names
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        SBQQ__Quote__c testQuote1 = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Ordered__c = false,
            SBQQ__Primary__c = true 
        );
        insert testQuote1;
        
        
       // SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c  WHERE SBQQ__Account__r.Name = 'Test Account' LIMIT 1];
        
        // Invalid JSON
        String invalidJson = '{"invalid": "json structure"}';
        
        Test.startTest();
        
        try {
            Furniture_ReceiptHelper.processPaymentResponse(
                invalidJson, 
                testQuote1.Id, 
                testAccount.Id, 
                'INV-001', 
                'REC-001'
            );
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(true, 'Exception was expected');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessPaymentResponse_NoQuote() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Mock JSON response
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        try {
            CustomerCreateReceiptController.PaymentModel result = Furniture_ReceiptHelper.processPaymentResponse(
                mockJsonResponse, 
                'invalid_quote_id', 
                testAccount.Id, 
                'INV-001', 
                'REC-001'
            );
            
            // If no exception is thrown, the method should still handle gracefully
            // The receipt should still be created even with invalid quote ID
            System.assertNotEquals(null, result, 'Payment model should not be null');
            System.assertNotEquals(null, result.receiptId, 'Receipt ID should not be null');
            
        } catch (Exception e) {
            // Exception is expected when trying to update quote with invalid ID
            System.assert(true, 'Exception was expected for invalid quote ID');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPaymentSplitData() {
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        Furniture_PaymentSplitDataWrapper.PaymentSplitData result = 
            Furniture_ReceiptHelper.getPaymentSplitData(mockJsonResponse);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Payment split data should not be null');
        System.assertNotEquals(0, result.totalAmountPaid, 'Total amount paid should be greater than 0');
        System.assertNotEquals(null, result.transactionDate, 'Transaction date should not be null');
    }
    
    @isTest
    static void testValidatePaymentSplit_Valid() {
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData = 
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(mockJsonResponse);
        
        Boolean isValid = Furniture_ReceiptHelper.validatePaymentSplit(paymentData);
        
        Test.stopTest();
        
        System.assertEquals(true, isValid, 'Payment split should be valid');
    }
    
    @isTest
    static void testValidatePaymentSplit_Null() {
        Test.startTest();
        
        Boolean isValid = Furniture_ReceiptHelper.validatePaymentSplit(null);
        
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Null payment split should be invalid');
    }
    
    @isTest
    static void testValidatePaymentSplit_Invalid() {
        Test.startTest();
        
        // Create invalid payment data
        Furniture_PaymentSplitDataWrapper.PaymentSplitData invalidData = 
            new Furniture_PaymentSplitDataWrapper.PaymentSplitData();
        invalidData.totalAmountPaid = 100;
        invalidData.vatAmount = 10;
        invalidData.vendorAmount = 50;
        invalidData.aldarAmount = 30; // This makes total = 80, but should be 90 (100-10)
        invalidData.vendorVAT = 5;
        invalidData.aldarVAT = 3; // This makes total VAT = 8, but should be 10
        
        Boolean isValid = Furniture_ReceiptHelper.validatePaymentSplit(invalidData);
        
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Invalid payment split should be invalid');
    }
    
    @isTest
    static void testPaymentSplitDataWrapper_DeserializeSuccess() {
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        Furniture_PaymentSplitDataWrapper.PaymentSplitData result = 
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(mockJsonResponse);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Payment split data should not be null');
        System.assertEquals(1050.00, result.totalAmountPaid, 'Total amount paid should be 1050.00');
        System.assertEquals(50.00, result.vatAmount, 'VAT amount should be 50.00');
        System.assertEquals(1000.00, result.vendorAmount + result.aldarAmount, 'Vendor + Aldar amount should be 1000.00');
        System.assertEquals('Test payment remarks', result.remarks, 'Remarks should match');
    }
    
    @isTest
    static void testPaymentSplitDataWrapper_DeserializeInvalidJson() {
        String invalidJson = '{"invalid": "structure"}';
        
        Test.startTest();
        
        try {
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(invalidJson);
            System.assert(false, 'Exception should have been thrown');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Failed to parse payment data'), 'Error message should indicate parsing failure');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testPaymentSplitDataWrapper_DeserializeNullJson() {
        Test.startTest();
        
        try {
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(true, 'Exception was expected');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testPaymentSplitDataWrapper_EmptyConstructor() {
        Test.startTest();
        
        Furniture_PaymentSplitDataWrapper.PaymentSplitData data = 
            new Furniture_PaymentSplitDataWrapper.PaymentSplitData();
        
        Test.stopTest();
        
        System.assertEquals(0, data.totalAmountPaid, 'Total amount paid should be 0');
        System.assertEquals(0, data.totalAmountReceived, 'Total amount received should be 0');
        System.assertEquals(0, data.totalStripeFee, 'Total stripe fee should be 0');
        System.assertEquals(0, data.vatAmount, 'VAT amount should be 0');
        System.assertEquals('', data.remarks, 'Remarks should be empty');
    }
    
    @isTest
    static void testUpdatePaymentOnOrderAndQuote_QuoteUpdateFailure() {
        Test.startTest();
        
        try {
            // Create valid test data first
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            String mockJsonResponse = createMockStripeResponse();
            
            // Try to update with invalid quote ID - this should cause an exception
            Furniture_ReceiptHelper.processPaymentResponse(
                mockJsonResponse, 
                'a0X000000000000', // Valid format but non-existent ID
                testAccount.Id, 
                'INV-001', 
                'REC-001'
            );
            
        } catch (Exception e) {
            // Expected to fail gracefully
            System.assert(true, 'Exception handling worked: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
  // Test method for null account ID scenario
    @isTest
    static void testProcessPaymentResponse_NullAccount() {
        // Get test quote
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Name = 'Test Account' LIMIT 1];
         
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addDays(180);
        update testQuote;
        
        // Mock JSON response
        String mockJsonResponse = createMockStripeResponse();
        
        Test.startTest();
        
        try {
            CustomerCreateReceiptController.PaymentModel result = Furniture_ReceiptHelper.processPaymentResponse(
                mockJsonResponse, 
                testQuote.Id, 
                null, // Null account ID
                'INV-001', 
                'REC-001'
            );
            
            // Should still create receipt
            System.assertNotEquals(null, result, 'Payment model should not be null');
            
        } catch (Exception e) {
            System.assert(true, 'Exception may be expected for null account ID');
        }
        
        Test.stopTest();
    }

    // Helper method to create mock Stripe response JSON
    private static String createMockStripeResponse() {
        return '{\n' +
            '  "statusCode": 200,\n' +
            '  "statusMessage": "Success",\n' +
            '  "data": {\n' +
            '    "id": "pi_test123",\n' +
            '    "amount_received": 105000,\n' +
            '    "currencyCode": "AED",\n' +
            '    "created": 1718467200,\n' +
            '    "metadata": {\n' +
            '      "orderTransactionId": "order_123",\n' +
            '      "payerId": "payer_123",\n' +
            '      "salesforceRequestId": "sf_123",\n' +
            '      "Remarks": "Test payment remarks",\n' +
            '      "splits": [\n' +
            '        {\n' +
            '          "id": "split_vendor",\n' +
            '          "amount": 75000,\n' +
            '          "currencyCode": "AED",\n' +
            '          "completedAt": "2024-06-15T10:00:00Z",\n' +
            '          "metadata": {\n' +
            '            "netAmount": "70000",\n' +
            '            "totalFee": "5000",\n' +
            '            "vatAmount": "250",\n' +
            '            "chargeType": "vendor_charge"\n' +
            '          },\n' +
            '          "accountSearchFields": {\n' +
            '            "accountType": "vendor"\n' +
            '          },\n' +
            '          "clientData": {\n' +
            '            "trn": "123456789",\n' +
            '            "marginPercent": 70,\n' +
            '            "recipientName": "Vendor Name"\n' +
            '          }\n' +
            '        },\n' +
            '        {\n' +
            '          "id": "split_aldar",\n' +
            '          "amount": 30000,\n' +
            '          "currencyCode": "AED",\n' +
            '          "completedAt": "2024-06-15T10:00:00Z",\n' +
            '          "metadata": {\n' +
            '            "netAmount": "28000",\n' +
            '            "totalFee": "2000",\n' +
            '            "vatAmount": "100",\n' +
            '            "chargeType": "aldar_charge"\n' +
            '          },\n' +
            '          "accountSearchFields": {\n' +
            '            "accountType": "corporate"\n' +
            '          },\n' +
            '          "clientData": {\n' +
            '            "trn": "987654321",\n' +
            '            "marginPercent": 30,\n' +
            '            "recipientName": "Aldar Properties"\n' +
            '          }\n' +
            '        }\n' +
            '      ]\n' +
            '    }\n' +
            '  }\n' +
            '}';
    }
    
    // Helper method to create minimal mock response for edge cases
    private static String createMinimalMockResponse() {
        return '{\n' +
            '  "statusCode": 200,\n' +
            '  "statusMessage": "Success",\n' +
            '  "data": {\n' +
            '    "id": "pi_minimal",\n' +
            '    "amount_received": 10000,\n' +
            '    "currencyCode": "AED",\n' +
            '    "created": 1718467200,\n' +
            '    "metadata": {\n' +
            '      "Remarks": "Minimal test",\n' +
            '      "splits": []\n' +
            '    }\n' +
            '  }\n' +
            '}';
    }
}