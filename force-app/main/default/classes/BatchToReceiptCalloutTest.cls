/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchToReceiptCallout
*/
@isTest
public class BatchToReceiptCalloutTest {
    @isTest
    public static void BatchToReceiptCalloutTest() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.ERPID__c = '12345';
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.IsCreatedFromLink__c = true;
        insert receiptAcknowledgement;

        // ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        // insert receiptAllocation;
        
        try {
            database.executeBatch(new BatchToReceiptCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Receipt Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Receipt Batch', '0 0 23 * * ?', new BatchToReceiptCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
}