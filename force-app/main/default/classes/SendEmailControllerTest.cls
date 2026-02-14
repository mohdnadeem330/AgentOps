/*
*Created By     : Sanath H M
*Created Date   : 15/01/2023
*Description    : Test class for SendEmailController
*/
@isTest
public class SendEmailControllerTest {
    
    static SalesOrder__c orderDetail ;
    static ReceiptAcknowledgement__c receiptRec ;
    static ReceiptAllocation__c receiptAllocationRecord ;
    static List<InstallmentLines__c> installmentLineList;
    
    static void init(){
        orderDetail = TestObjectsFactory.getSalesOrderData(false,'Grove-R15-01-01');
        
        Account Act = new Account(Id =orderDetail.Account__c, EmailAddress__pc = UserInfo.getUserEmail());
        update Act;
        
        receiptRec = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        insert receiptRec;
        installmentLineList = TestObjectsFactory.createInstallmentLines(orderDetail.Id, 2);
        receiptAllocationRecord = TestObjectsFactory.getReceiptAllocationRecord(receiptRec.Id, orderDetail.Id, orderDetail.Account__c, installmentLineList[0].Id);
        insert receiptAllocationRecord;
      }
    
    private static testMethod void getReceiptAdvice() {
        Test.startTest();
        init();
        PageReference pageRef = Page.ReceiptAdviceDocument;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', orderDetail.Id);

        System.debug('**orderDetail**'+orderDetail);
        SendEmailController.sendReceiptstoCustomers(orderDetail.Id, true,false);
         SendEmailController.sendReceiptstoCustomers(orderDetail.Id, false,true);
        Test.stopTest();
    }
}