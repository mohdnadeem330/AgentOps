/**
* DLPZoneTriggerHandlerTest
*
* Test class for DLPZoneTriggerHandler
*/
@isTest
private class DLPZoneTriggerHandlerTest{
     @isTest static void getDataTest() {
         DLPZone__c tempZone = new DLPZone__c();
         tempZone.name='test';
         tempZone.ProposedContractorDLPStartDate__c=system.today();
         tempZone.ProposedContractorDLPEndDate__c=system.today();
         insert tempZone;
         tempZone.ProposedContractorDLPStartDate__c = system.today().addDays(1);
         update tempZone;
     }
}