/* 
* StatusHandlerControllerTest
*
* Test class for StatusHandlerController
*/
@isTest
private class StatusHandlerControllerTest{
    //Create setup data
    @testSetup static void setupData() {
        User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'SalesManager');
        insert salesManager;
        
        RoundRobinAssignmentMatrix__c rrRecord = TestObjectsFactory.getAssignmentRecord(salesManager.Id);
        insert rrRecord;
    }
    //Access the RoundRobinAssignmentMatrix__c record and update the status
     @isTest static void testUtillity() {
         list<RoundRobinAssignmentMatrix__c> records = StatusHandlerController.getRRAssignmentRecord();
         
         list<RoundRobinAssignmentMatrix__c> records2 = StatusHandlerController.getRRAssignmentTeamRecord();
         StatusHandlerController.updateStatus(userInfo.getUserId(),false);
         StatusHandlerController.updateStatus(userInfo.getUserId(),true);
         
         RoundRobinAssignmentMatrix__c rrRecord= [select id,status__c from RoundRobinAssignmentMatrix__c where User__r.Profile.Name = 'Sales Manager' order by createdDate desc];
         System.assertEquals(rrRecord.status__c,Constants.STATUS_AVAILABLE);
     }
}