@isTest
public class PremPark_ReceiptHelperTest {
    
    @testSetUp
    public static void testData() {
        // Set up the test data for Account and Order
        Id personAccountRecordTypeId = utilities.getRecordTypeId('Account', 'Person Account');
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Agni';
        acc.PersonEmail = 'agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        insert acc;
        
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Opportunity';
        newOppty.Lead_Type__c = 'New Sale';
        newOppty.AccountId = acc.Id;
        newOppty.CloseDate = system.today().addDays(10);
        newOppty.StageName = 'New';
        newOppty.ExpectedEndDate__c = System.Today();
        insert newOppty;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,  
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;
        
        // Create a Quote with the 'Parking' Record Type
        //Id parkingRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND DeveloperName = 'Parking' LIMIT 1].Id;
                            Id parkingRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();

        
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Status__c = 'Draft',
            RecordTypeId = parkingRecordTypeId  // Assign 'Parking' Record Type
        );
        insert newQuote;
        
        // Create an Order without setting TotalAmount directly (calculated from OrderItems)
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = system.Today(),
            Pricebook2Id = pricebookId
        );
        insert ord;
        
        // Add OrderItems which will contribute to the TotalAmount calculation
        OrderItem orderItem = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 5,
            UnitPrice = 100.00
        );
        insert orderItem;
        
        // Insert ReceiptAcknowledgement__c records with different statuses to trigger the aggregation logic
        ReceiptAcknowledgement__c newReceiptAcknowledgementCleared = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Credit Note',
            Amount__c = 200.00,
            Order__c = ord.Id,
                    CPQQuote__c = newQuote.Id , // Link to the newly created Quote

            Status__c = 'Cleared'
        );
        insert newReceiptAcknowledgementCleared;
        
        ReceiptAcknowledgement__c newReceiptAcknowledgementReceived = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Credit Note',
            Amount__c = 150.00,
                    CPQQuote__c = newQuote.Id,// Link to the newly created Quote

            Order__c = ord.Id,
            Status__c = 'Received'
        );
        insert newReceiptAcknowledgementReceived;
        
        ReceiptAcknowledgement__c newReceiptAcknowledgementLinkSent = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Credit Note',
            Amount__c = 100.00,
                    CPQQuote__c = newQuote.Id,  // Link to the newly created Quote

            Order__c = ord.Id,
            Status__c = 'Link Sent'
        );
        insert newReceiptAcknowledgementLinkSent;
    }
    
    @isTest
    static void updateOrderPaymentsTest() {
        // Query ReceiptAcknowledgement__c records with multiple statuses
        List<ReceiptAcknowledgement__c> receiptToPas = [SELECT Id, Status__c, Order__c FROM ReceiptAcknowledgement__c];
        
        Set<Id> receiptIdSet = new Set<Id>();
        for (ReceiptAcknowledgement__c record : receiptToPas) {
            receiptIdSet.add(record.Id);
        }
        
        // Ensure there is at least one Order for aggregation
        List<Order> orders = [SELECT Id, TotalAmount, Amount_Received__c, Amount_In_Progress__c, Amount_Outstanding__c, Status 
                              FROM Order WHERE Id IN (SELECT Order__c FROM ReceiptAcknowledgement__c WHERE Id IN :receiptIdSet)];
        
        // Assert that Orders are found
        System.assert(!orders.isEmpty(), 'Orders should exist and be linked to ReceiptAcknowledgement__c records.');
        
        // Trigger the logic for updating order payments
        Test.startTest();
        PremPark_ReceiptHelper.updateOrderPayments(receiptIdSet);
        Test.stopTest();        
    }
    
    static testmethod void testStripePayments() {
        // Ensure test data for Stripe payments and the handlePremiumParkingReceipt method works
        ParkingServiceTest.createTestData();
        List<SBQQ__Quote__c> quoteList = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];        
        test.startTest();
        PremPark_ReceiptHelper.handlePremiumParkingReceipt(quoteList[0].Id, quoteList[0].SBQQ__Account__c, 'jsonBody', 'invoice', 100, 'receiptNumber');
        test.stopTest();
    }
    
    @isTest
    static void testHandleAfterInsert() {
        // Query the inserted receipt acknowledgements
        List<ReceiptAcknowledgement__c> receiptList = [SELECT Id FROM ReceiptAcknowledgement__c];
        Set<Id> receiptIdSet = new Set<Id>();
        
        for (ReceiptAcknowledgement__c rec : receiptList) {
            receiptIdSet.add(rec.Id);
        }
        
        Test.startTest();
        PremPark_ReceiptHelper.handleAfterInsert(receiptIdSet);
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200); 
            res.setBody('{"results":[{"sfRequestId":"123456","sfOrderId":"*","status":"ERP_ORDER_STATUS","errorMsg":null,"erpID":"1234567"}]}');
            return res;
        }
    }
}