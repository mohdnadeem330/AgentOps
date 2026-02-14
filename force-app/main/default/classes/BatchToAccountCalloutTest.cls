@isTest
public class BatchToAccountCalloutTest {
    /*
    * Purpose : To Test Covrage of Account Callout Batch
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testBatchToAccountCallout() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        acc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        try {
            database.executeBatch(new BatchToAccountCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Account Callout Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('Test Account Callout Batch', '0 0 23 * * ?', new BatchToAccountCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}