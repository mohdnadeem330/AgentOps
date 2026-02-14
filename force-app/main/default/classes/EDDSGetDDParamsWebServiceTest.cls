@isTest
public class EDDSGetDDParamsWebServiceTest {

     @isTest
    public static void doPostTest() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/getDDParamsForAccount');
        EDDSGetDDParamsWebService.doPost(salesOrder1.id, new List<String>{acc.Id,acc2.Id},'NewSale');
        EDDSGetDDParamsWebService.doPost(salesOrder1.id, new List<String>{acc.Id,acc2.Id},'NewLeasing');
        EDDSGetDDParamsWebService.doPost(salesOrder1.id, new List<String>{acc.Id,acc2.Id},'Retail');
        EDDSGetDDParamsWebService.doPost(null, null,'NewSale');
        EDDSGetDDParamsWebService.doPost(null, null,null);

        RestContextHandler handler = new RestContextHandler(false);
    }
}