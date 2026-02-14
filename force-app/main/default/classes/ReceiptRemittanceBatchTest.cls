@isTest
public class ReceiptRemittanceBatchTest {

     static SalesOrder__c orderDetail ;
    static ReceiptAcknowledgement__c receiptRec ; 
    
    static void init(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        Insert acc;
        orderDetail = TestObjectsFactory.getSalesOrderData(false,'Grove-R15-01-01');
        receiptRec = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
//        receiptRec.status__c = 'Scanned';
        receiptRec.RemittanceAmount__c = 100;
        receiptRec.RemittanceChequeDateText__c = '15-08-2022';
        receiptRec.RemittanceChequeNumber__c = '211';
        receiptRec.RecievedFromAccount__c = acc.Id;
        Insert receiptRec;
        ReceiptAcknowledgement__c receiptRec2 = TestObjectsFactory.getReceiptAcknowledgementRecord(orderDetail.Id, orderDetail.Account__c, orderDetail.Opportunity__c, 'Cheque');
        receiptRec2.RecievedFromAccount__c = acc.Id;
//        receiptRec2.status__c = 'Scanned';
        receiptRec2.RemittanceAmount__c = 100000;
        receiptRec2.RemittanceChequeDateText__c = '15-08-2022';
        receiptRec2.RemittanceChequeNumber__c = '1234567890';
        Insert receiptRec2;
    }
    
    private static testMethod void getReceiptAdvice() {
        init();
        Test.startTest();
        try{
        database.executeBatch(new ReceiptRemittanceBatch(), 100);
            
        }catch(Exception e){
            system.debug('EXCEPTION '+e.getMessage());
        }
        Test.stopTest();
    }
}