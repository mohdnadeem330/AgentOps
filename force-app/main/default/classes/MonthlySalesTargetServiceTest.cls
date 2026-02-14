/*
*Created By     : Hardik Vitthani
*Description    : Test class for MonthlySalesTargetService
*/
@isTest
public class MonthlySalesTargetServiceTest {
    @isTest
    public static void MonthlySalesTargetServiceTest() {
        Test.startTest();

        MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(UserInfo.getUserId(), Constants.USER_TEAM_DXB);
        insert monthlySalesTarget;

        MonthlySalesTargetService.fetchMonthlySalesTargetForAPIByUser(UserInfo.getUserId());
        MonthlySalesTargetService.fetchAgentRank(UserInfo.getUserId());
        MonthlySalesTargetService.fetchMonthlySalesTargetRank();

        Test.stopTest();
    }
}