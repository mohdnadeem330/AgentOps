@isTest(SeeAllData=false)
public class SalesOrderCancellationWebServiceTest {
    @isTest static void setupMethod() {

        User salesAdminUser = TestObjectsFactory.getUserRecord('Sales Admin', 'salesadmin1');
        insert salesAdminUser;

        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        insert opportunityRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        SalesOrderCancellation__c orderCancellation = new SalesOrderCancellation__c();
        orderCancellation.SalesOrder__c = salesOrder.Id;
        orderCancellation.ReasonforCancellation__c = 'Mortage Rejected';
        orderCancellation.SalesManagerComments__c = 'Customer requested to cancell';
        orderCancellation.AllInstallmentProvided__c = true;
        orderCancellation.SalesOrderStatusWhenCancelled__c = 'Pending with CM';
                
        TestObjectsFactory.initializeRestContext(null, '/upsert/ordercancellation ');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        
        SalesOrderCancellationWebService.doPost(orderCancellation, salesAdminUser.Id);
        
        orderCancellation.ReasonforCancellation__c = 'Other reason';

        Test.startTest();                
        SalesOrderCancellationWebService.doPost(orderCancellation, salesAdminUser.Id);
        Test.stopTest();

    }
}