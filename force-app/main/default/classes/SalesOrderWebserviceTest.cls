@isTest(SeeAllData=false)
public class SalesOrderWebserviceTest {
    @isTest static void setupMethod() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        //acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, salesOrder.Id);
        insert document;
        
        TestObjectsFactory.initializeRestContext(null, '/query/salesorderdetails');
        SalesOrderWebservice.doPost(salesOrder.id);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        DocumentQueryModel documentQueryModel = new DocumentQueryModel();
        
        Test.startTest();
        //insert leadTask;
        //insert opportunityTask;
        //update leadRecord;
        
        //TestObjectsFactory.initializeRestContext(null, '/query/activity');
        SalesOrderWebservice.doPost(salesOrder.id);
        
        Test.stopTest();

    }
}