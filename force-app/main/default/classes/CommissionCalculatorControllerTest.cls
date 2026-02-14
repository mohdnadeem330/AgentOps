@isTest
public class CommissionCalculatorControllerTest {

    @isTest
    Public static void getSaleManagersTest(){
        string strMonth = String.valueOf(date.today().month()-1);
        string strYear = String.valueOf(date.today().year());
        SalesManagerCommissionLineBatchTest.getData('Inventory',Constants.TEAM_LAND,Constants.WEALTH);
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = [SELECT AcceleratorCommissionAmount__c,AcceleratorPercentage__c,TargetAmount__c,
                                                             TargetMonth__c,KPI1__c,KPI2__c,TargetYear__c,
                                                             AcceleratorTargetAmount__c,ResourceName__c,
                                                             KPIPayoutPercentage__c FROM MonthlySalesTarget__c 
                                                             WHERE TargetMonth__c =: strMonth AND TargetYear__c =: strYear];
        Test.startTest();
        CommissionCalculatorController.getSaleManagers('Sales Manager');
        CommissionCalculatorController.getSaleManagersCommission('Sales Manager', lstMonthlySalesTarget[0].ResourceName__c,  strMonth,  strYear);
        CommissionCalculatorController.getSaleManagersCommission('Broker Manager', lstMonthlySalesTarget[0].ResourceName__c,  strMonth,  strYear);
        Test.stopTest();
    }
}