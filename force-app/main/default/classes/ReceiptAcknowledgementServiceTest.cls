/*
*Created By     : Hardik Vitthani
*Description    : Test class for ReceiptAcknowledgementService
*/
@isTest
public class ReceiptAcknowledgementServiceTest {
    @isTest
    public static void testReceiptAcknowledgementService() {
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
        insert receiptAllocation;
        
        try {
            ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(new List<Id>{receiptAcknowledgement.Id});
            ReceiptAcknowledgementService.getReceiptAcknowledgementById(receiptAcknowledgement.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
}