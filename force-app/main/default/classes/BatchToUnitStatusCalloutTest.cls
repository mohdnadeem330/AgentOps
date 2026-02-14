/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchToUnitStatusCallout AND UnitUpdateWrapper
*/
@isTest
public class BatchToUnitStatusCalloutTest {
    @isTest
    public static void testUnitStatusCallout() {
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.StatusSyncStatus__c = 'Error';
        unit.ReprocessCallout__c = Constants.REPROCESS_STATUS;
        unit.SellingPrice__c = 100000;
        unit.SellingPriceComments__c = 'Test';
        unit.SellingPriceRevisionNumber__c = 1;
        insert unit;

        try {
            database.executeBatch(new BatchToUnitStatusCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Unit Status Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Unit Status Batch', '0 0 23 * * ?', new BatchToUnitStatusCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}