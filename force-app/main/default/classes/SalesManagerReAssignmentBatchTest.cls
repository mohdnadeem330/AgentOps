/* SalesManagerReAssignmentBatchTest
*
* Test class for SalesManagerReAssignmentBatch
*/
@isTest
private class SalesManagerReAssignmentBatchTest{
    //Create Test Data
    @testSetup static void setupData() {
        User salesManager;
        User u = [Select Id from User where Profile.Name = 'System Administrator' AND isActive=true AND Id !=: UserInfo.getUserId() Limit 1];
        system.runAs(u){
            salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'SalesManager');
            insert salesManager;
        }
       
        RoundRobinAssignmentMatrix__c rrRecord = TestObjectsFactory.getAssignmentRecord(salesManager.Id);
        insert rrRecord;
       
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        personAcc.MobilePhone__pc = '9999999999';
        insert personAcc;

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;

    }

    //Executing the batch Class
     @isTest static void testBatch() {
     
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStatusCode(200);
         mock.setStaticResource('GetBitlyShortenURLSuccess');
         Test.setMock(HttpCalloutMock.class, mock);

        Id queueId = [SELECT Id from Group WHERE Type = 'Queue' AND Name = 'Sales Manager RR Queue'].Id;
         
        // Create Lead From Account Record
        Account personAcc = [select id from account limit 1];
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.ExistingAccount__c = personAcc.Id;
        leadRec.IsCreateFromExistingAccount__c = true;
        leadRec.KioskSection__c  = 'Request A Call Back';
        leadRec.OwnerId = queueId;
        insert leadRec;
        
        
         list<Lead> leadRecord=[select id,Status,OwnerId, Project__c from Lead limit 1];
         leadRecord[0].AssignmentSLATime__c=system.now().addDays(-5);
         LeadTriggerHandler.checkAndCreateTask(new map<id,Lead>(leadRecord));
         
         update leadRecord;
         RoundRobinAssignmentMatrix__c rrRecord= [select id,status__c from RoundRobinAssignmentMatrix__c where User__r.Profile.Name = 'Sales Manager' order by createdDate desc];
         System.assertEquals(rrRecord.status__c,Constants.STATUS_AVAILABLE);
         
         test.startTest();
         SalesManagerReAssignmentBatch smBatch = new SalesManagerReAssignmentBatch();
         smBatch.execute(null, new List<Lead>{leadRec});
            System.schedule('SalesManagerReAssignmentBatch-Test', '0 0 * * * ?', new SalesManagerReAssignmentBatch() );
         test.stopTest();
     }
}