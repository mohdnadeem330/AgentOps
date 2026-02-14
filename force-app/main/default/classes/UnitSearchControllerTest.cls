/* 
* UnitSearchControllerTest
*
* Test class for UnitSearchController
*/
@isTest(SeeAllData=false)
public class UnitSearchControllerTest {

    @IsTest 
    public static void testgetBlockedReasonsByUserRole() {
        List<String> SalesManagersUsersRoles = new List<String>();
        SalesManagersUsersRoles.add('ONLINE');
        SalesManagersUsersRoles.add('VIP SALE');
        SalesManagersUsersRoles.add('SALES');
        SalesManagersUsersRoles.add('BULK SALE');
        SalesManagersUsersRoles.add('MGMT SALES');
        SalesManagersUsersRoles.add('CANCELLATION-LEGAL RESTRICTION');
        SalesManagersUsersRoles.add('DEV RESTRICTION');

        List<String> Test= UnitSearchController.getBlockedReasonsByUserRole(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR);
    }
    
    
    @IsTest
    public static void testUpdateUnit() {
        List<String> unitId = new List<String>();

        Project__c p= TestObjectsFactory.getProjectRecord('45223452');
        insert p;
        BuildingSection__c b= TestObjectsFactory.getBuildingDetailRecord(p.id);
        insert b;
        Unit__c u = TestObjectsFactory.getUnitDetail(p.id,b.id);
        insert u;

        //AllocationGroup__c al = TestObjectsFactory.getAllocationGroupRecord('Test AG');
        //insert al;

        User us = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'TestUser');
        insert us;
        unitId.add(u.id);

        boolean testParam1= UnitSearchController.updateUnit(null, 'null', 'Available', '',unitId, '', 'null', 'null');
    	boolean testParam2= UnitSearchController.updateUnit('null', us.id, 'Blocked', 'SALES', unitId, 'SALES', us.id, 'currentDate');
        System.assertEquals(true,testParam1); 
        System.assertEquals(true,testParam2); 
    }
}