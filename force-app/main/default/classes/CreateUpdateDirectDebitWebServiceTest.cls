@isTest
public class CreateUpdateDirectDebitWebServiceTest {

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
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit.Id;
        insert salesOrder2;
        
        DirectDebitRequest__c ddr2 = TestObjectsFactory.createDirectDebitRecords(salesOrder2.id);
        insert ddr2;
        
        TestObjectsFactory.initializeRestContext(null, '/upsert/directDebit');
        CreateUpdateDirectDebitWebService.doPost(salesOrder1.id, 'Passport','Savings', 'Abu Dhabi Commercial Bank',
                              '1234567890', 'Test',  'AE123456789012345678901',  true,'', 'remark', acc.Id);
        CreateUpdateDirectDebitWebService.doPost(salesOrder2.id, 'Passport','Savings', 'Abu Dhabi Commercial Bank',
                              '1234567890', 'Test',  '123456789012345678901',  true, ddr2.id, 'remark', acc.Id);
         
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
    }
}