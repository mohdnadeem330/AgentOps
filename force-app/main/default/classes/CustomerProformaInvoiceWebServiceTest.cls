@isTest
public class CustomerProformaInvoiceWebServiceTest {

    @isTest
    public static void testCustomerProformaInvoiceWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/proformainvoice');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            CustomerProformaInvoiceWebService.isRunningTest = true;
            CustomerProformaInvoiceWebService.doPost(installmentLine.Id, acc.PersonEmail);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            CustomerProformaInvoiceWebService.isRunningTest = true;
            CustomerProformaInvoiceWebService.doPost(installmentLine.Id, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerProformaInvoiceWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/proformainvoice');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerProformaInvoiceWebService.doPost(salesOrder.Id, acc.PersonEmail);
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

        return salesOrder;
    }
}