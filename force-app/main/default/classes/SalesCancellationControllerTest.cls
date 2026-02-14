/*
*Created By     : Hardik Vitthani
*Description    : Test class for ShareHelper
*/
@isTest
public class SalesCancellationControllerTest {
    @isTest
    public static void testGetSalesOrderDetails() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Directdebitauthorityreferencenumber__c = '1234567890';
        insert salesOrder;

        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.Status__c = 'Cancellation in progress';
        insert ddr; 
        
        try {
            SalesCancellationController.getSalesOrderDetails(salesOrder.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void getCancellationReasonsTest() {
        Test.startTest();
        
        List<String> reasons = SalesCancellationController.getCancellationReasons();
        
        Assert.areNotEqual(0, reasons.size());
        
        Test.stopTest();
    }
        
}