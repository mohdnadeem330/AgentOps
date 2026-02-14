@isTest
public class ReceiptNOCController_Test {
    
    static SalesOrder__c orderDetail ;
    static ReceiptAcknowledgement__c receiptRec ; 
    
    static void init(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        Insert acc;
        orderDetail = TestObjectsFactory.getSalesOrderData(false,'Grove-R15-01-01');
        receiptRec = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        receiptRec.RecievedFromAccount__c = acc.Id;
        Insert receiptRec;
        ReceiptAcknowledgement__c receiptRec2 = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        receiptRec2.RecievedFromAccount__c = acc.Id;
        Insert receiptRec2;
    }
    
    private static testMethod void getReceiptAdvice() {
        Test.startTest();
        init();
        PageReference pageRef = Page.ReceiptAdviceDocument;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', orderDetail.Id);
    
        System.debug('**orderDetail**'+orderDetail);
        ReceiptNOCController.getReceiptDetails(orderDetail.Id);
        ReceiptNOCController.getSalesOrderReceipts();
        Test.stopTest();
    }
}