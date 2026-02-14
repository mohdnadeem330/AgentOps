/*
*****************************************************************************
Apex Class Name : ADHAReminderBatchTest
Created Date    : Sept 04, 2023
@description    : This class is developed to cover class ADHAReminderBatch
@author         : Moh Sarfaraj

Modification Log:
Ver   Date              Author                               Modification
1.0   04-09-2023      Moh Sarfaraj                          Initial Version
******************************************************************************
*/
@isTest 
public class ADHAReminderBatchTest {
    @testSetup
    static void createData(){
        Group g1 = new Group(Name = 'ADHA Queue', type = 'Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.Id, SobjectType = 'Lead');
        insert q1;
   
        Group groupDetail = [SELECT Id,Name,DeveloperName,Email,Type FROM Group where Type = 'Queue' LIMIT 1];
        
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.pruat');

        System.runAs(u) {
            Integer count = 0;
            List<Lead> listLeads = new List<Lead>();
            for(Integer i=0 ;i<10;i++){
                Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
                leadRec.LeadSource = '800-Aldar' ;
                leadRec.EnquiryCategory__c = 'Kiosk' ;
                leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
                leadRec.AssignToRoundRobin__c = false;
                leadRec.Bag_Lead_Assigned_Manually_TO_RM__c = false;
                leadRec.OwnerId = groupDetail.Id;
                leadRec.SendReminder__c = count < 5 ? 'Reminder 1' : count < 7 ? leadRec.SendReminder__c = 'Reminder 2' : '';
                listLeads.add(leadRec);
                count++;
            }
            insert listLeads;
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStatusCode(200);

            //Success Mock
            mock.setStaticResource('GetSMSNotificationSuccess');
            Test.setMock(HttpCalloutMock.class, mock);
        }
    }
    
    static testMethod void unitTest(){
        Test.startTest();
        List<Lead> listLeads = [SELECT Id,CreatedDate,SendReminder__c,AssignToRoundRobin__c,Bag_Lead_Assigned_Manually_TO_RM__c FROM Lead];
        ADHAReminderBatch obj = new ADHAReminderBatch();
        
        Database.QueryLocator ql = obj.start(null);
        obj.execute(null,listLeads);
        obj.Finish(null);
        obj.execute(null);
        Test.stopTest();
    }
}