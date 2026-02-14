@isTest
public with sharing class EDDSGetDirectDebitWebServiceTest {

     @isTest
    public static void doPostTest() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/getDirectDebits');
        EDDSGetDirectDebitWebService.doPost(salesOrder1.id, acc.Id,'NewSale');
        EDDSGetDirectDebitWebService.doPost(acc.id, salesOrder1.Id,'NewSale');
        EDDSGetDirectDebitWebService.doPost(null, null,null);
        EDDSGetDirectDebitWebService.doPost(null, null,'NewLeasing');
        EDDSGetDirectDebitWebService.doPost(null, null,'Retail');
         
        //TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
    }
}