@isTest
public class SessionControlTriggerTest {
    
    //Creating Setp data
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
         
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
    }
    

    @isTest
    static void testSessionControlTrigger() {
        
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        System.runAs(userRecord){
        Test.startTest();
        // Create a test SessionControlEvent__e record
        SessionControlEvent__e testEvent = new SessionControlEvent__e(
            SessionId__c = 'TestSessionId'
        );
        Database.SaveResult sr = EventBus.publish(testEvent);

        // Verify the publication was successful
        System.assert(sr.isSuccess()); 

        // Query for the AuthSession record created by the trigger
        List<AuthSession> authSessions = [SELECT Id FROM AuthSession WHERE Id = :testEvent.SessionId__c];
        System.assertEquals(0, authSessions.size(), 'AuthSession record should be deleted by trigger');
        Test.stopTest();
        }
    }
}