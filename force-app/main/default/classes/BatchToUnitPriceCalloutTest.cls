/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchToUnitPriceCallout AND UnitUpdateWrapper
*/
@isTest
public class BatchToUnitPriceCalloutTest {
    @isTest
    public static void testUnitPriceCallout() {
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.PriceSyncStatus__c = 'Error';
        unit.ReprocessCallout__c = Constants.REPROCESS_PRICE;
        unit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        unit.AssignedToUser__c = UserInfo.getUserId();
        insert unit;

        try {
            database.executeBatch(new BatchToUnitPriceCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Unit Price Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Unit Price Batch', '0 0 23 * * ?', new BatchToUnitPriceCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}