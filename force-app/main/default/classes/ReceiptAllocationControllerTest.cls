/*
*Created By     : Hardik Vitthani
*Description    : Test class for ReceiptAllocationController
*/
@isTest
public class ReceiptAllocationControllerTest {
    @isTest
    public static void testGetReceiptAllocationbyReceiptId() {
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
            ReceiptAllocationController.getReceiptAllocationbyReceiptId(receiptAcknowledgement.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetRelatedAccountbyAccountId() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        AccountRelationship__c accRelationship = TestObjectsFactory.getAccountRelationship(acc.Id, acc2.Id, 'Third Party');
        insert accRelationship;
        
        try {
            ReceiptAllocationController.getRelatedAccountbyAccountId(acc.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testGetRelatedSalesOrderbyAccountId() {
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
        
        try {
            ReceiptAllocationController.getRelatedSalesOrderbyAccountId(acc.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInvoicesApplicableForSO() {
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
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        try {
            ReceiptAllocationController.getInvoicesApplicableForSO(salesOrder.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testSaveReceiptAllocation() {
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
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;

        String receiptAllocations = '[{"Id":"' + receiptAllocation.Id + '","amountApplied":100}';
        receiptAllocations += ',{"Id":"","amountApplied":100,"isInstallment":true,"installmentOtherChargeId":"' + installmentLineList[1].Id + '","accountId":"' + acc.Id + '","salesOrderId":"' + salesOrder.Id + '"}';
        receiptAllocations += ',{"Id":"","amountApplied":100,"isInstallment":false,"installmentOtherChargeId":"' + salesOrderOtherCharge.Id + '","accountId":"' + acc.Id + '","salesOrderId":"' + salesOrder.Id + '"}]';
        try {
            ReceiptAllocationController.saveReceiptAllocation(receiptAllocations, receiptAcknowledgement.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}