@isTest(SeeAllData=false)
public class ManageUsersControllerTest {

    @isTest
    public static void testgetUserRoles() {
        List<String> SalesManagersUsersRoles = new List<String>();
        SalesManagersUsersRoles.add('Sales Manager - AUH');
        SalesManagersUsersRoles.add('Sales Manager - VIP');
        SalesManagersUsersRoles.add('Sales Manager - DXB');
        SalesManagersUsersRoles.add('Sales Manager - Land');

        List<String> Test= ManageUsersController.getUserRoles();
    	System.assertEquals(SalesManagersUsersRoles,Test); 
    }

    @IsTest
    public static void testManageUsersController() {
        List<String> allocationGroupUserstring = new List<String>();
        List<Id> allocationGroupUserId = new List<Id>();
        List<String> userId = new List<String>();

        AllocationGroup__c al = TestObjectsFactory.getAllocationGroup('Grove Luanch 2022','GROVE2022');
        insert al;

        User us = TestObjectsFactory.getUserRecord('Sales Manager', 'TestUser');
        us.ResourceId__c= '345736345';
        insert us;

        userId.add(us.id);
        Date startDate = system.today().addDays(10);
        Date endDate = system.today().addDays(20);

    	boolean Test1= ManageUsersController.CreateAllocationGroupUser(userId,startDate,endDate,al.id);
        AllocationGroupUser__c allocationGroupUser = [SELECT id from AllocationGroupUser__c WHERE User__c =: us.id  AND AllocationGroup__c =: al.id Limit 1];
        allocationGroupUserstring.add(allocationGroupUser.id);
        allocationGroupUserId.add(allocationGroupUser.id);
        boolean Test2= ManageUsersController.UpdateAllocationGroupUser(allocationGroupUserstring,startDate,endDate);
    	boolean Test3= ManageUsersController.removeAllocationGroupUser(allocationGroupUserId);
    	System.assertEquals(true,Test1); 
        System.assertEquals(true,Test2);
        System.assertEquals(true,Test3); 
    }
    
}