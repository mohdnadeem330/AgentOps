@isTest(SeeAllData=false)
public class BudgetaryControlEmailControllerTest {
    @isTest static void setupData() {

        ProjectBudget__c budgetRecord = TestObjectsFactory.getProjectBudget();
        insert budgetRecord;
        List<BudgetLines__c> budgetLinesList = new  List<BudgetLines__c>();
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Mortgage Subsidy','7.73.770',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Darna Loyalty','7.73.751',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Other Sales Support','7.73.739',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Home Maintenance','7.73.741',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('SC Waiver','7.73.736',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Sales Comm.-Internal','7.73.731',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Forfeited Cash','7.73.761',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Sales Comm.-External','7.73.732',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_TASK_PAYMENT_PROVISION,CONSTANTS.BUDGET_TASK_PAYMENT_PROVISION,budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_LINE_DISCOUNT,'7.73.737',budgetRecord.Id,Constants.BUDGET_DISCOUNT_REBATE_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_LINE_REBATE,'7.73.738',budgetRecord.Id,Constants.BUDGET_DISCOUNT_REBATE_BUCKET));
        insert budgetLinesList ;
        
		BudgetaryControlEmailController emailController = new BudgetaryControlEmailController();
        emailController.pBId = budgetRecord.Id ; 
        List<BudgetaryControlEmailController.ProjectBudgetDataWrapper> discountWrapper = emailController.dicountDataReqList ;
        List<BudgetaryControlEmailController.ProjectBudgetDataWrapper> wrapper = emailController.projectBudgetDataReqList ;
        
        BudgetaryControlEmailController.ProjectBudgetDataWrapper projectBudgetDataWrapper = new BudgetaryControlEmailController.ProjectBudgetDataWrapper('',null,null,null);
                
    }
}