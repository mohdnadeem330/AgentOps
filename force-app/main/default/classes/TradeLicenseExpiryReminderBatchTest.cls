/**
* TradeLicenseExpiryReminderBatchTest
*
* Test class for TradeLicenseExpiryReminderBatch
*/
@isTest
private class TradeLicenseExpiryReminderBatchTest{
     //Setup data
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.RegistrationExpiryDate__c=system.today();
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
    }
    //Testing Email communication
    @isTest static void testCommunicationEmail() {
        
        test.startTest();
                Database.executeBatch(new TradeLicenseExpiryReminderBatch(),100);
        test.stopTest();
        
    }
    //Testing Email communication
    @isTest static void testScheduleCommunicationEmail() {
        
        test.startTest();
                System.schedule('TradeLicenseExpiryReminderBatchTest', '0 25 * * * ?', new TradeLicenseExpiryReminderBatch() );
        test.stopTest();
        
    }
}