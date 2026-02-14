/*
*Created By     : Pavithra Gajendra
*Created Date   : 29/07/2022
*Description    : Test class for ReceiptAdviceDocumentController
*/
@isTest
private class ReceiptAdviceDocumentControllerTest {
    
    static SalesOrder__c orderDetail ;
    static ReceiptAcknowledgement__c receiptRec ;
    static ReceiptAllocation__c receiptAllocationRecord ;
    static List<InstallmentLines__c> installmentLineList;
    
    static void init(){
        DDTransactionResponseHandler.stopExecuteReceiptAckTrigger = true;
        orderDetail = TestObjectsFactory.getSalesOrderData(false,'Grove-R15-01-01');
        receiptRec = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        insert receiptRec;
        installmentLineList = TestObjectsFactory.createInstallmentLines(orderDetail.Id, 2);
        receiptAllocationRecord = TestObjectsFactory.getReceiptAllocationRecord(receiptRec.Id, orderDetail.Id, orderDetail.Account__c, installmentLineList[0].Id);
        insert receiptAllocationRecord;
        //receiptAllocationRecord = TestObjectsFactory.getReceiptAllocationRecord(receiptRec.Id,orderDetail.Id, );
        
    }

    private static testMethod void getReceiptAdvice() {
        Test.startTest();
        init();
        PageReference pageRef = Page.ReceiptAdviceDocument;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', orderDetail.Id);

        System.debug('**orderDetail**'+orderDetail);
        ReceiptAdviceDocumentController.getSalesOrderReceipts();
        Test.stopTest();
    }
    
    private static testMethod void getReceipt() {
        Test.startTest();
        init();
        PageReference pageRef = Page.ReceiptDocument;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('salesOrderId', orderDetail.Id);
        ApexPages.currentPage().getParameters().put('paymentId', installmentLineList[0].Id);

        ReceiptAdviceDocumentController.getInstallmentOrOtherChargesReceipt();
        Test.stopTest();
    }
  
    private static testMethod void testParkingReceipt(){
        init();
        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        // Get Standard Pricebook ID
        Id pricebookId = Test.getStandardPricebookId();
        // Create Contact
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id);
        insert testContact;
        // Create Contract
        Contract testContract = new Contract(
            AccountId = testAccount.Id, 
            Status = 'Draft', 
            StartDate = Date.today(), 
            ContractTerm = 12
        );
        insert testContract;
        // Create Order

        Order testOrder = new Order(
            AccountId = testAccount.Id, 
            ContractId = testContract.Id, 
            EffectiveDate = Date.today(), 
            Sales_Order__c = orderDetail.Id,
            Status = 'Draft'
        );
        insert testOrder;
        
        // Create Receipt Acknowledgement
        ReceiptAcknowledgement__c newReceiptAcknowledgementOrder = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Online',
            Order__c = testOrder.Id,
            Amount__c = 100000,
            ClearedDate__c = Date.Today(),
            Remarks__c = 'Test Remark',
            CustomerBankAccount__c = '1234567890',
            ReferenceNumber__c = '1234567890',
            MortgageCheque__c = true,
            MaturityDate__c = Date.today(),
            Status__c = 'Received'
        );
        insert newReceiptAcknowledgementOrder;
        Test.startTest();
        PageReference pageRef = Page.ReceiptDocument;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('salesOrderId', orderDetail.Id);
        ApexPages.currentPage().getParameters().put('paymentId', testOrder.Id);

        ReceiptAdviceDocumentController.getInstallmentOrOtherChargesReceipt();
        Test.stopTest();
    }
}