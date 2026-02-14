@isTest
public class CustomerHomeWebserviceTest {

    @isTest
    public static void testCustomerHomeWebservice() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/home');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerHomeWebservice.doPost(acc.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerHomeWebserviceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/home');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerHomeWebservice.doPost('test');
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
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        return salesOrder;
    }
}