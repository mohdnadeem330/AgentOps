/**
* EventTriggerHandlerTest
*
* Test class for EventTriggerHandler
*/
@isTest
private class EventTriggerHandlerTest{
    //create setup Data
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
    }
    //Test email deletion event
    @isTest static void testEventDelete() {
        Event eventRecord = new Event();
        eventRecord.Subject='test';
        //eventRecord.WhatId = leadRecord[0].Id;
        eventRecord.StartDateTime = System.now();
        eventRecord.EndDateTime = System.now().addDays(1);
        insert eventRecord ;
        User integrationProfile = TestObjectsFactory.getUserRecord(Constants.INTEGRATION_PROFILE, 'integrationProfile');
        insert integrationProfile;
        System.runAs(integrationProfile) {
            list<Event> taskRecords = [select id from Event];
            try{
            delete taskRecords;
            }catch(Exception e){
                
            }
        }
        list<Event> evtRecords = [select id from Event];
        //System.assertEquals(evtRecords.isEmpty(), false);
    }
    
}