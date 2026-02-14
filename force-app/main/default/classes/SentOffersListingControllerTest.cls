/* 
* SentOffersListingControllerTest
*
* Test class for SentOffersListingController
*/
@isTest
public class SentOffersListingControllerTest {
     @testSetup static void setupData() {
            //Createthe test data
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
         
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
            orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
            insert orgAcc;
           
            Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
            
            User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
            agencyAdminUser.contactId=conRecord.Id;
            insert agencyAdminUser;
    
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            opp.BrokerAgentContact__c=conRecord.Id;
            opp.BrokerAgencyAccount__c =orgAcc.Id;
            insert opp;
         
            // Create Lead From Account Record
            Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
            leadRec.ExistingAccount__c = acc.Id;
            leadRec.IsCreateFromExistingAccount__c = true;

            insert leadRec;
     }
     //retrive the sent offer details
    @IsTest
    public static void SentOffersListingTest() {
        list<SentOffersListingController.SentOffersListingWrapper> recordList= SentOffersListingController.getActivityHistory();
        System.assertNotEquals(null,recordList); 
        Contact conRecord = [select id from Contact limit 1];
        
        Lead leadrecord = [select id,Project__c, firstName, lastName, Email from Lead limit 1];
        Opportunity opptyRecord = [select id,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,Project__c from Opportunity limit 1];
        String subjectVals= 'Offer Letter for the Aldar Project';
        Task leadTask = new Task(Subject=subjectVals,
                    WhoId=leadrecord.Id,
                    //WhatId = leadrecord.Id,
                    TaskNumber__c = 9,
                    ReminderDateTime= System.now().addDays(-5), 
                    IsReminderSet=true,
                    TaskType__c=Constants.TASK_TYPE_DAY1,
                    ActivityDate= System.today().addDays(-5),
                    OwnerId= userInfo.getUserId());
        Task opptyTask = new Task(Subject=subjectVals,
                    WhoId=conRecord.id,
                    WhatId = opptyRecord.Id,
                    TaskNumber__c = 9,
                    ReminderDateTime= System.now().addDays(-5), 
                    IsReminderSet=true,
                    TaskType__c=Constants.TASK_TYPE_DAY1,
                    ActivityDate= System.today().addDays(-5),
                    OwnerId= userInfo.getUserId());
        insert new list<Task>{leadTask,opptyTask};
            
        map<id,Contact> conMap = new map<Id,Contact>([select id from Contact]);
        User userRecord = [select id,AccountId from User where contactId = :conMap.keySet() limit 1];
        System.runAs(userRecord) {
            recordList= SentOffersListingController.getActivityHistory();
        }
        SentOffersListingController.SentOffersListingWrapper obj = new SentOffersListingController.SentOffersListingWrapper(null,null,leadrecord);
        obj = new SentOffersListingController.SentOffersListingWrapper(opptyRecord,null,null);
    }

    
}