@isTest
public class BatchToSalesOrderCalloutTest {
    /*
    * Purpose : To Test Covrage of Sales Order Callout Batch
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testBatchToSalesOrderCallout() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        salesOrder.SyncStatus__c = Constants.STATUS_FAILED;
        update salesOrder;

        try {
            database.executeBatch(new BatchToSalesOrderCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Sales Order Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Sales Order Batch', '0 0 23 * * ?', new BatchToSalesOrderCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}