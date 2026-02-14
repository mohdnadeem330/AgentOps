@istest
public class CreateWriteOffReceiptTest {
    
    @isTest
    public static void testReceiptWriteOff(){
        
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        receiptAllocation.TypeOfInvoice__c = 'Adjustment';
        insert receiptAllocation;
        
        try {
            // Create a mock HTTP request
            String body = JSON.serialize(new List<ReceiptAllocation__c>{receiptAllocation});
            system.debug('body = '+body);
            // Set up the request context
            RestRequest req = new RestRequest();
            req.requestURI = '/query/useExistingAccount/';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueof(body);
            RestContext.request = req;
            
            // Set up the response context
            RestResponse res = new RestResponse();
            RestContext.response = res;
            CreateWriteOffReceipt.doPost();
            body = JSON.serialize(receiptAllocation);
            req.requestBody = Blob.valueof(body);
            CreateWriteOffReceipt.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
}