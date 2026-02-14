@isTest
private class BatchToAGUserRevokeAccessTest {
    
    static AllocationGroup__c allocationGroup; 
    static AllocationGroupUser__c newGroupUser;

    static void init(){
        allocationGroup = TestObjectsFactory.getAllocationGroup('Dubai Team','DXB');
        insert allocationGroup ;
        AllocationGroup__c allocationGroupDetail = [SELECT Id,StartDate__c,EndDate__c,PublicGroupAssociated__c FROM AllocationGroup__c WHERE Id=:allocationGroup.Id];
        User userDetail = Utilities.getLoggedInUserDetail();
        newGroupUser = TestObjectsFactory.getAllocationGroupUser(userDetail,allocationGroupDetail);
        insert newGroupUser ;
    }

    /*
    * Scenario 1 : Remove users from public group
    */
    private static testMethod void removeUsers() {

        init();
        allocationGroup.StartDate__c = allocationGroup.StartDate__c.addDays(-2);
        allocationGroup.EndDate__c = allocationGroup.EndDate__c.addDays(-31);
        update allocationGroup ;
        Test.startTest();
        BatchToAllocationGroupUserRevokeAccess revokeAccess = new BatchToAllocationGroupUserRevokeAccess();
        database.executeBatch(revokeAccess,200);
        String timeSchedule ='0 48 * * * ?'; 
        System.schedule('Remove unit access', timeSchedule,revokeAccess);
        Test.stopTest();
    }

}