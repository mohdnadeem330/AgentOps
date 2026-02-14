@isTest
public class EDDSGetEligibilityWebServiceTest {

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
        
        TestObjectsFactory.initializeRestContext(null, '/edds/directDebitEligibility');
        EDDSGetEligibilityWebService.doPost(salesOrder1.id, acc.Id,'NewSale');
        EDDSGetEligibilityWebService.doPost(acc.id, salesOrder1.Id,'NewSale');
        EDDSGetEligibilityWebService.doPost(null, null,null);
        EDDSGetEligibilityWebService.doPost(null, null,'NewLeasing');
        EDDSGetEligibilityWebService.doPost(null, null,'Retail');
         
        //TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
    }
}