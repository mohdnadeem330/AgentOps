/*
*Created By     : Hardik Vitthani
*Description    : Test class for ReceiptAllocationTriggerHandler
*/
@isTest
public class ReceiptAllocationTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        //Dummy commit as part of SSP-647
        // Create test data for ReceiptAllocation_Integration_Fields__c custom setting
        ReceiptAllocation_Integration_Fields__c field1 = new ReceiptAllocation_Integration_Fields__c();
        field1.Name = 'AmountApplied';
        field1.API__c = 'AmountApplied__c';
        field1.Is_Active__c = true;
        
        ReceiptAllocation_Integration_Fields__c field2 = new ReceiptAllocation_Integration_Fields__c();
        field2.Name = 'InstallmentLine';
        field2.API__c = 'InstallmentLine__c';
        field2.Is_Active__c = true;
        
        ReceiptAllocation_Integration_Fields__c field3 = new ReceiptAllocation_Integration_Fields__c();
        field3.Name = 'SalesOrderOtherCharges';
        field3.API__c = 'SalesOrderOtherCharges__c';
        field3.Is_Active__c = true;
        
        insert new List<ReceiptAllocation_Integration_Fields__c>{field1, field2, field3};
    }
    
    @isTest
    public static void testReceiptAllocationTriggerHandler() {
        //FIN-140 Dummit comment
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        Test.startTest();
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[1].Id);
        insert receiptAllocation;
        
        ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation1;
        
        TriggerHandler.processedIds = new Set<Id>();
        receiptAllocation.AmountApplied__c = 2000;
        update receiptAllocation;

        Test.stopTest();
    }
}