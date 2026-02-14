@isTest
public class EDDSUpdateDirectDebitWebServiceTest {

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
        ddr1.EDDS_DDAID__c = '123';
        insert ddr1;
        
        DDTransaction__c ddTransaction = new DDTransaction__c();
        ddTransaction.RequestType__c = 'New Registration';
        ddTransaction.TransactionStatus__c =  'Unprocessed';
        ddTransaction.DirectDebitRequest__c = ddr1.Id;
        ddTransaction.EDDS_DDAID__c = ddr1.EDDS_DDAID__c;
        insert ddTransaction;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/getDDParamsForAccount');
        EDDSUpdateDirectDebitWebService.doPost(ddr1.EDDS_DDAID__c, '','','','');
        EDDSUpdateDirectDebitWebService.doPost(ddr1.EDDS_DDAID__c, 'Sent to Bank','NewRegistration','NewSale','QUNLSFIsQUNDRVBURUQsQzMwMDAwMzAwMDE1MTIzMDIwMTIzNDU1Ni5ERFMsMzAwMjMwMTI3MDAwMDg0Ng0KQUNLVFIsQUNDRVBURUQsMiwwMDNEQVIyMzAxMjcwMjRC');
        EDDSUpdateDirectDebitWebService.doPost(ddr1.EDDS_DDAID__c, 'Sent to Bank','Cancellation','NewSale','QUNLSFIsQUNDRVBURUQsQzMwMDAwMzAwMDE1MTIzMDIwMTIzNDU1Ni5ERFMsMzAwMjMwMTI3MDAwMDg0Ng0KQUNLVFIsQUNDRVBURUQsMiwwMDNEQVIyMzAxMjcwMjRC');

        RestContextHandler handler = new RestContextHandler(false);
    }
}