/**
* RoundRobinAssignmentUtilityTest
*
* Test class for RoundRobinAssignmentUtility
*/
@isTest
private class RoundRobinAssignmentUtilityTest{
    //Create test data
    @testSetup static void setupData() {
        User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'SalesManager');
        salesManager.IsActive = true;
        salesManager.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1].Id;
        insert salesManager;
        
       

        

    }
    //testing RR Unitity class
     @isTest static void testUtillity() {
         Id userId = [SELECT Id,IsActive FROM User WHERE Profile.Name = 'Sales Manager' AND IsActive = true LIMIT 1].Id;
          RoundRobinAssignmentMatrix__c rrRecord = TestObjectsFactory.getAssignmentRecord(userId);
        insert rrRecord;
         
         RoundRobinAssignmentMatrix__c r1 = [SELECT Id,User__c,User__r.Profile.Name,User__r.IsActive,Status__c FROM RoundRobinAssignmentMatrix__c WHERE Id=:rrRecord.id];
        system.debug('rrRecord:'+r1.User__r.IsActive);
         user u = [SELECT Id, Profile.Name,profileId FROM User WHERE Id=:r1.User__c];
       system.debug('PName:'+[SELECT Id,Name FROM Profile WHERE Id=:u.profileId]);
         Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        insert personAcc;

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;
          
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStatusCode(200);
         mock.setStaticResource('GetBitlyShortenURLSuccess');
         Test.setMock(HttpCalloutMock.class, mock);
         
         Account personAcc1 = [select id from Account where recordType.Name= 'Person Account' limit 1];
         // Create Lead From Account Record
         Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
         leadRec.ExistingAccount__c = personAcc1.Id;
         leadRec.IsCreateFromExistingAccount__c = true;
         insert leadRec;
         
         RoundRobinAssignmentUtility.setAgentOffline(new set<ID>{userInfo.getUserId()});
         
         RoundRobinAssignmentUtility.setAgentAvailable(new set<ID>{userInfo.getUserId()});
         RoundRobinAssignmentMatrix__c rrRecord1= [select id,status__c,User__c,User__r.Profile.Name,User__r.IsActive from RoundRobinAssignmentMatrix__c where User__r.Profile.Name = 'Sales Manager' order by createdDate desc];
         System.assertEquals(rrRecord1.status__c,Constants.STATUS_AVAILABLE);
         
         RoundRobinAssignmentUtility.getAgentAvailibility(new set<ID>{userInfo.getUserId()});
         RoundRobinAssignmentUtility.getAvailibleAgentWorkCapacity(new set<ID>{userInfo.getUserId()});
         RoundRobinAssignmentUtility.getActionSLA(2);
         
         RoundRobinAssignmentUtility.updateRRLoadCounter(new map<id,RoundRobinAssignmentMatrix__c>([select id,status__c,User__c,User__r.Profile.Name,User__r.IsActive from RoundRobinAssignmentMatrix__c where User__c = :userInfo.getUserId() order by createdDate desc]));
         list<Lead> leadRecord=[select id from Lead limit 1];
         //RoundRobinAssignmentUtility.getAvailableAgent(new Set<ID>{leadRecord.Id});
         RoundRobinAssignmentUtility.getAgentAssignment(new map<id,Lead>(leadRecord));
         RoundRobinAssignmentUtility.removeReassignmentCounter(new set<ID>{leadRecord[0].Id});
     }
}