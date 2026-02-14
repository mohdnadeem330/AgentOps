@isTest
public class CancelDirectDebitWebServiceTest {

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
        CancelDirectDebitWebService.doPost(ddr2.Id, 'test remarks cancellation');
        CancelDirectDebitWebService.doPost('asdfghj', 'test remarks cancellation');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
    }
}