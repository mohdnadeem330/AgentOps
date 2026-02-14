global with sharing class BudgetaryControlEmailController {

    global String pBId{get;set;}

    global BudgetaryControlEmailController() {
    }

    global
        List<ProjectBudgetDataWrapper> projectBudgetDataReqList{
        get{        
            Integer counter = 1;
            List<ProjectBudgetDataWrapper> projectBudgetDataToDisplay = new List<ProjectBudgetDataWrapper>();

            ProjectBudgetWrapper projectBudgetData = BudgetLinesService.getAvailableProjectBudgetJSON(pBId);

            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Internal Commission',
            projectBudgetData.totalinternalCommissionAmount,
            projectBudgetData.availableinternalCommissionAmount,
            projectBudgetData.internalCommissionAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('External Commission',
            projectBudgetData.totalexternalCommissionAmount,
            projectBudgetData.availableexternalCommissionAmount,
            projectBudgetData.externalCommissionAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('ADM Waiver Fee',
            projectBudgetData.totalADMWaiverFee,
            projectBudgetData.availableADMWaiverFee,
            projectBudgetData.ADMWaiverFee));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('SC Waiver',
            projectBudgetData.totalSCWaiverAmount,
            projectBudgetData.availableSCWaiverAmount,
            projectBudgetData.SCWaiverAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Other Sales Support',
            projectBudgetData.totalotherSalesSupportAmount,
            projectBudgetData.availableotherSalesSupportAmount,
            projectBudgetData.otherSalesSupportAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Home Maintenance',
            projectBudgetData.totalhomeMaintenanceWaiverFee,
            projectBudgetData.availablehomeMaintenanceWaiverFee,
            projectBudgetData.homeMaintenanceWaiverFee));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Darna Loyalty',
            projectBudgetData.totaldarnaLoyalty,
            projectBudgetData.availabledarnaLoyalty,
            projectBudgetData.darnaLoyalty));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Payment Provisions',
            projectBudgetData.totalPaymentProvisionAmount,
            projectBudgetData.availablePaymentProvisionAmount,
            projectBudgetData.utilizedPaymentProvisionAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Mortgage Subsidy',
            projectBudgetData.totalmortgageSubsidy,
            projectBudgetData.availablemortgageSubsidy,
            projectBudgetData.availableMortgageSubsidy));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Forfeited Cash',
            projectBudgetData.totalForfeitedAmount,
            projectBudgetData.availableForfeitedAmount,
            projectBudgetData.utilizedForfeitedAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Total Sum',
            projectBudgetData.totalSalesSupportBucket,
            projectBudgetData.availableSalesSupportBucket,
            projectBudgetData.utilizedSalesSupportBucket));
            
            return  projectBudgetDataToDisplay;
        }
        set;
    }

    global List<ProjectBudgetDataWrapper> dicountDataReqList{
        get{        
            Integer counter = 1;
            List<ProjectBudgetDataWrapper> projectBudgetDataToDisplay = new List<ProjectBudgetDataWrapper>();
    
            ProjectBudgetWrapper projectBudgetData = BudgetLinesService.getAvailableProjectBudgetJSON(pBId);
    
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Discount',
            projectBudgetData.totaldiscountAmount,
            projectBudgetData.availablediscountAmount,
            projectBudgetData.discountAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Rebate',
            projectBudgetData.totalRebateAmount,
            projectBudgetData.availablerebateAmount,
            projectBudgetData.rebateAmount));
            projectBudgetDataToDisplay.add(new ProjectBudgetDataWrapper('Total Sum',
            projectBudgetData.totalDiscountandRebateBucket,
            projectBudgetData.availableDiscountandRebateBucket,
            projectBudgetData.utilizedDiscountandRebateBucket));
            
            return  projectBudgetDataToDisplay;
        }
        set;
    }
    
    public class ProjectBudgetDataWrapper {

        public String taskName { get; set; }
        public Decimal budgetDefined { get; set;}
        public Decimal availableBudget { get; set;}
        public Decimal budgetUtilized { get; set;}

        public ProjectBudgetDataWrapper(String taskName, Decimal budgetDefined, Decimal availableBudget, Decimal budgetUtilized) {
          this.taskName = taskName;
          if (budgetDefined != null) {
            this.budgetDefined = budgetDefined;
          }else{
            this.budgetDefined = 0.00;
          }
          if (availableBudget != null) {
            this.availableBudget = availableBudget;
          }else{
            this.availableBudget = 0.00;
          }
          if (budgetUtilized != null) {
            this.budgetUtilized = budgetUtilized;
          }else{
            this.budgetUtilized = 0.00;
          }
        }
      
    }

}