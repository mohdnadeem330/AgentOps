@isTest
public class BatchToJointOwnerCalloutTest {
    /*
    * Purpose : To Test Covrage of Joint Owner Callout Batch
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testBatchToJointOwnerCallout() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        insert jointOwner;

        jointOwner.SyncStatus__c = Constants.STATUS_FAILED;
        update jointOwner;

        try {
            database.executeBatch(new BatchToJointOwnerCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Joint Owner Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Joint Owner Batch', '0 0 23 * * ?', new BatchToJointOwnerCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}