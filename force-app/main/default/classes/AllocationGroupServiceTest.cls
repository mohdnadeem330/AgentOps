/*
*Created By     : Pavithra Gajendra
*Created Date   : 26/07/2022
*Description    : Test class for AllocationGroupTriggerHandler and AllocationGroupService
*/
@isTest
private class AllocationGroupServiceTest {

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
    * Scenario 1 : Create Allocation Group
    */
    private static testMethod void createGroup() {
        Test.startTest();
        init();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Update Allocation Group to end date less than today
    */
    private static testMethod void updateGroup() {
        Test.startTest();
        init();
        TriggerHandler.processedIds = new Set<Id>();
        AllocationGroup__c newAllocationGroup = new AllocationGroup__c();
        newAllocationGroup.Id = allocationGroup.Id ;
        newAllocationGroup.StartDate__c = allocationGroup.StartDate__c.addDays(-2);
        newAllocationGroup.EndDate__c = allocationGroup.EndDate__c.addDays(-31);
        update newAllocationGroup ;
        Test.stopTest();
    }

    /*
    * Scenario 3 : Update Allocation Group to end date more than today
    */
    private static testMethod void updateGroupEndDateFuture() {
        Test.startTest();
        init();
        TriggerHandler.processedIds = new Set<Id>();
        AllocationGroup__c newAllocationGroup = new AllocationGroup__c();
        newAllocationGroup.Id = allocationGroup.Id ;
        newAllocationGroup.StartDate__c = allocationGroup.StartDate__c.addDays(-2);
        newAllocationGroup.EndDate__c = allocationGroup.EndDate__c.addDays(-31);
        update newAllocationGroup ;
        TriggerHandler.processedIds = new Set<Id>();
        newAllocationGroup.EndDate__c = allocationGroup.EndDate__c.addDays(35);
        update newAllocationGroup ;
        Test.stopTest();
    }

    /*
    * Scenario 4 : Create Allocation Group with Length Name
    */
    private static testMethod void createGroupWithLargeName() {
        Test.startTest();
        allocationGroup = TestObjectsFactory.getAllocationGroup('Grove Project Lovure Residences Launch Dubai Team','GROVEDXB');
        insert allocationGroup ;
        Test.stopTest();
    }

    /*
    * Scenario 5 : Execute Allocation Group Service Methods
    */
    private static testMethod void testAllocationGroupService() {
        Test.startTest();
        init();
        AllocationGroupService.getAllocationGroupNames();
        AllocationGroupService.getAllocationGroupCodes();
        AllocationGroupService.getAllocationGroupQuery('Select Id From AllocationGroup__c');
        AllocationGroupService.addAllocationGroupUserToGroup(new List<Id>{newGroupUser.Id});
        Test.stopTest();
    }
}