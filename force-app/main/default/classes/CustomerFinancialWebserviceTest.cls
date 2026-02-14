@isTest
public class CustomerFinancialWebserviceTest {

    @isTest
    public static void testCustomerFinancialWebservice() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/financial');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerFinancialWebservice.doPost(acc.Id, salesOrder.Id, '', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    // Added by neelesh start here  
    @isTest
    public static void testCustomerFinancialWebservice1() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;
        SalesOrder__c salesOrder = getData(acc);        
        TestObjectsFactory.initializeRestContext(null, '/query/financial');
        RestContextHandler handler = new RestContextHandler(false);
         Order parkingOrder = new Order(
            AccountId = acc.Id,
            Sales_Order__c = salesOrder.Id,
          //  TotalAmount = 1000,
            Amount_Outstanding__c = 200,
            Amount_Received__c = 800,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert parkingOrder;
        
        Test.startTest();
        try {
            CustomerFinancialWebservice.doPost(acc.Id, salesOrder.Id, CustomerAPIConstants.PARKING_PAYMENT, CustomerAPIConstants.PAYMENT_STATUS_PAID);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
     @isTest
    public static void testCustomerFinancialWebservice2() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;
        SalesOrder__c salesOrder = getData(acc);        
        TestObjectsFactory.initializeRestContext(null, '/query/financial');
        RestContextHandler handler = new RestContextHandler(false);
         Order parkingOrder = new Order(
            AccountId = acc.Id,
            Sales_Order__c = salesOrder.Id,
          //  TotalAmount = 1000,
            Amount_Outstanding__c = 200,
            Amount_Received__c = 800,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert parkingOrder;
        
        Test.startTest();
        try {
            CustomerFinancialWebservice.doPost(acc.Id, salesOrder.Id, CustomerAPIConstants.PARKING_PAYMENT, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
        // Added by neelesh end here  

    @isTest
    public static void testCustomerFinancialWebserviceWitoutSO() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/financial');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerFinancialWebservice.doPost(acc.Id, '', '', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerFinancialWebserviceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/financial');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerFinancialWebservice.doPost(acc.Id, acc.Id, '', '');
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