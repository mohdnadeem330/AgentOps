/*
*Created By     : Pavithra Gajendra
*Created Date   : 26/07/2022
*Description    : Test class for AllocationGroupTriggerHandler and AllocationGroupService
*/
@isTest
private class AllocationGroupUserServiceTest {
    
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
    * Scenario 1 : Create Allocation Group User
    */
    private static testMethod void createGroup() {
        Test.startTest();
        init();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Update Allocation Group User end date
    */
    private static testMethod void updateGroup() {
        Test.startTest();
        init();
        TriggerHandler.processedIds = new Set<Id>();
        AllocationGroupUser__c allocationGroupUser = new AllocationGroupUser__c();
        allocationGroupUser.Id = newGroupUser.Id ;
        allocationGroupUser.EndDate__c = allocationGroup.EndDate__c.addDays(-31);
        update allocationGroupUser ;
        Test.stopTest();
    }

    /*
    * Scenario 3 : Delete Allocation Group User end date
    */
    private static testMethod void deleteGroup() {
        Test.startTest();
        init();
        AllocationGroupUser__c allocationGroupUser = new AllocationGroupUser__c();
        allocationGroupUser.Id = newGroupUser.Id ;
        delete allocationGroupUser ;
        Test.stopTest();
    }

    /*
    * Scenario 4 : AllocationGroupService methods execution
    */
    private static testMethod void allocationGroupUser() {
        Test.startTest();
        init();
        AllocationGroupUserService.newAllocationGroupMembers(new List<AllocationGroupUser__c>{newGroupUser});
        Map<Id,Set<Id>> publicGroupUserMap = AllocationGroupUserService.getPubliGroupUserMap(new Set<Id>{newGroupUser.Id});
        //AllocationGroupUserService.addUsersToPublicGroup(publicGroupUserMap);
        //AllocationGroupUserService.deletedAllocationGroupMembers(new List<AllocationGroupUser__c>{newGroupUser});
        Test.stopTest();
    }
}