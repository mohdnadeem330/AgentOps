/*
*Created By     : Pavithra Gajendra
*Created Date   : 27/07/2022
*Description    : Test class for BudgetLinesService
*/
@isTest
private with sharing class BudgetLinesServiceTest {

    static ProjectBudget__c budgetRecord ;
    static List<BudgetLines__c> budgetLinesList;
    static List<Unit__c> unitRecords ;
    static SalesOfferUtility.PaymentPlanWrapper paymentPlanWrapper ;
    
    static void init(){
        budgetRecord = TestObjectsFactory.getProjectBudget();
        insert budgetRecord ;
        budgetLinesList = new  List<BudgetLines__c>();
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Mortgage Subsidy','7.73.770',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('ADM Fee','7.73.735',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
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
        Set<Id> unitIds = new Set<Id>();
        Unit__c unitRec = TestObjectsFactory.unitDataSetup('GroveTest-B1-30-01');
        insert unitRec ;
        unitIds.add(unitRec.Id); 
        unitRecords = UnitService.getAllUnitsById(unitIds);
        paymentPlanWrapper = new SalesOfferUtility.PaymentPlanWrapper();
        paymentPlanWrapper.rebateAmount = 3000 ;
        paymentPlanWrapper.admFeeWaiverAmount = 3000 ;
        paymentPlanWrapper.serviceChargeAmount = 3000 ;
        paymentPlanWrapper.homeMaintenanceWaiverFee = 3000 ;
        paymentPlanWrapper.darnaAmount = 3000 ;
        paymentPlanWrapper.externalComissionAmount = 3000 ;
        paymentPlanWrapper.internalComissionAmount = 3000 ;
        paymentPlanWrapper.mortgageSubsidy = 3000 ;
        paymentPlanWrapper.discountAmount = 3000 ;
        paymentPlanWrapper.otherSalesSupportAmount = 3000 ;

        SalesOrder__c orderdetail = TestObjectsFactory.getSalesOrderData(false,'GroveTest-B1-30-02');
        orderdetail.ProjectBudget__c = budgetRecord.Id ;
        orderdetail.BookingDate__c = Date.today(); 
        update orderdetail ; 
        
        
    }
    
   
    /*
    * Scenario 1 : Check Avaialble Budget
    */
    private static testMethod void checkProjectBudget() {
        Test.startTest();
        init();
        Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper = new Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();
        unitPaymentPlanWrapper.put(unitRecords[0],paymentPlanWrapper);
        BudgetLinesService.checkAvailableProjectBudget(new Set<Id>{budgetRecord.Id},unitPaymentPlanWrapper);
        Test.stopTest();
    }

    /*
    * Scenario 2 : Invoke Budget Lines Method
    */
    private static testMethod void budgetLineService() {
        
        budgetRecord = TestObjectsFactory.getProjectBudget();
        insert budgetRecord ;
        budgetLinesList = new  List<BudgetLines__c>();
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Mortgage Subsidy','7.73.770',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('ADM Fee','7.73.735',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
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
       Test.startTest();
        List<ProjectBudget__c> budgetRecordLst = [SELECT Id FROM ProjectBudget__c];
        SalesOrder__c cancelOrderdetail = TestObjectsFactory.getSalesOrderData(true,'GroveTest-B1-30-03');
        cancelOrderdetail.ProjectBudget__c = budgetRecordLst[0].Id ;
        cancelOrderdetail.SalesOrderCancelledDate__c = Date.today(); 
        cancelOrderdetail.Status__c = Constants.SO_STATUS_CANCELLED ;
        update cancelOrderdetail ;
        BudgetLinesService.getBudgetLinesQuery('Select Id From BudgetLines__c');
        BudgetLinesService.getAvailableProjectBudgetJSON(budgetRecord.Id);
        Test.stopTest();
    }
       
}