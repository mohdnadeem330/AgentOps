@isTest
public class CustomerPaymentWebServiceTest {

    @isTest
    public static void testCustomerPaymentWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);

        InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        
        TestObjectsFactory.initializeRestContext(null, '/query/payment');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerPaymentWebService.doPost(installmentLine.Id, Constants.ONLINE, date.today(), 1000, '123456', null, null, 'test', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerPaymentWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/payment');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerPaymentWebService.doPost(salesOrder.Id, Constants.ONLINE, date.today(), 1000, '123456', null, null, 'test', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    public static SalesOrder__c getData(Account acc) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        salesOrder.Is_Digital_Sales__c = true;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        return salesOrder;
    }
}