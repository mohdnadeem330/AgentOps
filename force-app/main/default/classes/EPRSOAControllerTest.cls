@isTest
public class EPRSOAControllerTest {
    
     @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        insert salesOrder;  
    }
    
    @isTest static void getERPSOATest() {
        List<SalesOrder__c> SalesOrderList =[select Id,Unit__r.Name from SalesOrder__c limit 1];
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new EPRSOAControllerTestMockResponse());
        EPRSOAController.SoaWrapperResp resp=EPRSOAController.getERPSOA(SalesOrderList.get(0).Id);
        Test.StopTest();
    }

}