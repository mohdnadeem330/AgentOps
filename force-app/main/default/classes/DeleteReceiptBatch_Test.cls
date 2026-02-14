@isTest
public class DeleteReceiptBatch_Test {
    @isTest
    public static void deleteReceiptBatchTestMethod1() {
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
        receiptAcknowledgement.IsCreatedFromLink__c = true;
        receiptAcknowledgement.Markfordeletion__c = true;
        insert receiptAcknowledgement;
        
        try {
            database.executeBatch(new DeleteReceiptBatch(), 100);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
}