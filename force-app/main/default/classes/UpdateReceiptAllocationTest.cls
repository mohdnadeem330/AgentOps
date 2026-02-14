@isTest
public class UpdateReceiptAllocationTest {
    @isTest
    public static void unitTest1() {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
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
        salesOrder.ADMFeeAmount__c = 20000;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        test.startTest();
        UpdateReceiptAllocationQueueable obj = new UpdateReceiptAllocationQueueable(new List<ReceiptAllocation__c>{receiptAllocation});
        System.enqueueJob(obj);
        test.stopTest();
    }


}