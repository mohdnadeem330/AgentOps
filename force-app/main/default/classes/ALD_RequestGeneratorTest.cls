@IsTest
public class ALD_RequestGeneratorTest {
    @isTest
    public static void testGenerateSalesOrderRequest() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c='12345';
        insert acc;
        
        SalesOrder__c salesOrder = getData(acc, false);
        
        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            Map<String, String> newMap = new Map<String, String>();
            newMap.put(acc.Id, '12344');
            ALD_RequestGenerator.generateSalesOrderRequest(soIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
        
    }
    public static SalesOrder__c getData(Account acc, Boolean isSaleCancellation) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        if (isSaleCancellation) {
            SalesOrderCancellation__c salesCancellation = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder.Id, unit.Id);
            salesCancellation.Cancellation_Status__c = 'Approved';
            insert salesCancellation;
        }

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        TestObjectsFactory.createOpportunityOfferLines(salesOrder.Id, 5);
        TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);

        return salesOrder;
    }
    
    @isTest
    public static void testCustomerCalloutPerson() {
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        pAcc.OtherERPID__c = '{"temp":"temp"}';
        insert pAcc;

        List<Id> accIds = new List<Id>();
        accIds.add(pAcc.Id);
        try {
            ALD_RequestGenerator.generateCustomerRequest(accIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testReceiptCalloutHelper() {
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

        List<Id> raIds = new List<Id>();
        raIds.add(receiptAcknowledgement.Id);
        try {
            ALD_RequestGenerator.generateReceiptRequest(raIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
    
}