@isTest 
public without sharing class BlkReceiptAckControllerTest {
    
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
        update con;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        
    }
    
     static testmethod void doPost() { 
       List<ReceiptAcknowledgement__c> receiptList=[select Id,Name from ReceiptAcknowledgement__c];
       Test.startTest(); 
       BlkReceiptAckController.RequestWrapper reqWrapper=new BlkReceiptAckController.RequestWrapper();
       List<BlkReceiptAckController.ReceiptAckRequestWrapper> receipts=new  List<BlkReceiptAckController.ReceiptAckRequestWrapper>();
       BlkReceiptAckController.ReceiptAckRequestWrapper ackRequestWrapper=new  BlkReceiptAckController.ReceiptAckRequestWrapper();
       ackRequestWrapper.sfId=receiptList.get(0).Id;
       ackRequestWrapper.status='Cleared';
       ackRequestWrapper.statusReason ='';
       ackRequestWrapper.receiptNumber='6269731';
       ackRequestWrapper.amount='10000';
       ackRequestWrapper.eRPID='2701610';
       ackRequestWrapper.receiptDate='2023-02-28';
       ackRequestWrapper.clearedDate='2023-02-28';
         
        BlkReceiptAckController.ReceiptAckRequestWrapper ackRequestWrapper1=new  BlkReceiptAckController.ReceiptAckRequestWrapper();
      // ackRequestWrapper1.sfId='uyt765745465465';
       ackRequestWrapper1.status='Cleared';
       ackRequestWrapper1.statusReason ='';
       ackRequestWrapper1.receiptNumber='6269731';
       ackRequestWrapper1.amount='10000';
       ackRequestWrapper1.eRPID='2701610';
       ackRequestWrapper1.receiptDate='2023-02-28';
       ackRequestWrapper1.clearedDate='2023-02-28';      
       receipts.add(ackRequestWrapper);
       receipts.add(ackRequestWrapper1);
       reqWrapper.receipts=receipts; 
        System.debug('ReceiptAckRequestWrapper ****'+reqWrapper);
       
        TestObjectsFactory.initializeRestContext(null, '/update/ReceiptAck');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(reqWrapper));
        List<BlkReceiptAckController.ReceiptAckResponseWrapper> responseList=BlkReceiptAckController.doPost();
        Test.stopTest();
        System.debug('ReceiptAckResponseWrapper ****'+responseList);
    }

}