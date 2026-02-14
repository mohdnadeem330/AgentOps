/*
*Created By     : Pavithra Gajendra
*Created Date   : 11/08/2022
*Description    : Test class for ReceiptAcknowledgementDocumentController
*/
@isTest
private class ReceiptAckDocumentControllerTest {
    
    static SalesOrder__c orderDetail ;
    static ReceiptAcknowledgement__c receiptRec ;
    
    static void init(){
        orderDetail = TestObjectsFactory.getSalesOrderData(false,'Grove-R15-01-07');
        receiptRec = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        insert receiptRec;
    }

    private static testMethod void getReceiptAdvice() {
        Test.startTest();
        init();
        PageReference pageRef = Page.ReceiptAcknowledgementDocument;
        Test.setCurrentPage(pageRef); 
        ApexPages.currentPage().getParameters().put('id', orderDetail.Id);

        System.debug('**orderDetail**'+orderDetail);
        ReceiptAcknowledgementDocumentController.getSalesOrderReceipts();
        Test.stopTest();
    }
    
}