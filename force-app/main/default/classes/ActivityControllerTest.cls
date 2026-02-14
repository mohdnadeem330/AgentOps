/**
* ActivityControllerTest
*
* Test class for ActivityController
*/
@isTest
private class ActivityControllerTest{
    //Setup data
    @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc2;

        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
        BrokerActivities__c brokerActivityRecord = new BrokerActivities__c();
        brokerActivityRecord.StartDate__c = system.today();
        brokerActivityRecord.Name='Test';
        brokerActivityRecord.Description__c ='Test';
        brokerActivityRecord.Type__c = BrokerActivities__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        brokerActivityRecord.Status__c = BrokerActivities__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
        insert brokerActivityRecord;

		ActivityMapping__c actMap = new ActivityMapping__c();
        actMap.Agency__c = orgAcc.Id;
        actMap.Activity__c = brokerActivityRecord.Id;
        insert actMap;
    }
        
    
    //Test Without activity and eventsf
    @isTest 
    static void testActivities() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
        System.runAs(userRecord) {
            list<ActivityController.ActivityDetails> activityList = ActivityController.getMyAgencyEventsActivities();
          //  System.assertEquals(activityList.isEmpty(),true);
            ActivityController.getMyAgencyEvents();
            ActivityController.getMyAgencyActivity();
            ActivityController.getAllAgency('abc');
            ActivityController.getAllAgency(null);
            ActivityController.getSelectedAgency(null);
        }
    }
    //Test with activity and events
    @isTest static void testActivitySave() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
        BrokerActivities__c brokerActivityRecord = [select id from BrokerActivities__c limit 1];
        list<Document__c> documentrecords = [select id,DocumentType__c,Activity__c from Document__c where Activity__c = :brokerActivityRecord.id ];
        System.assertEquals(documentrecords.isEmpty(),false);
        for(Document__c docRecord : documentrecords){
        	OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
        }
        list<string> accIdString = new list<string>();
        list<Account> accountList = [select id from Account];
        for(Account accId : accountList ){
            accIdString.add(accId.id);
        }
        list<ActivityMapping__c> activityMappingList = [select id,Agency__c from ActivityMapping__c where Activity__c = :brokerActivityRecord.id ];
        ActivityController.saveActivityMapping(brokerActivityRecord.id,accIdString,false);
     //   ActivityController.saveActivityMapping(brokerActivityRecord.id,new list<String>{accountList[1].Id},false);
     //   ActivityController.saveActivityMapping(brokerActivityRecord.id,new list<String>{accountList[0].Id,accountList[1].Id},false);
       
        System.runAs(userRecord) {
            ActivityController.getMyAgencyEventsActivities();
            ActivityController.getMyAgencyEvents();
        }
    }

    
}