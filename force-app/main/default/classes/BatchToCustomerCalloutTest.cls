@isTest
public class BatchToCustomerCalloutTest {
    /*
    * Purpose : To Test Covrage of Customer Callout Batch
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testBatchToCustomerCallout() {
        Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Organisation Account', 'TestRegistrationNo');
        oAcc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
        insert oAcc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(oAcc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, oAcc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<Id> accIds = new List<Id>();
        accIds.add(oAcc.Id);
        try {
            database.executeBatch(new BatchToCustomerCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Customer Callout Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('Test Customer Callout Batch', '0 0 23 * * ?', new BatchToCustomerCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}