public with sharing class BudgetLinesService {

    @AuraEnabled(cacheable=false)
    public static List<BudgetLines__c> getBudgetLinesQuery(String query){
        List<BudgetLines__c> records = Database.query(query);
        return records;
    }

    /*
    * Get List of all the budget lines for the project
    */
    public static List<BudgetLines__c> getAllBudgetLines(Set<Id> projectBudgetId){
        List<BudgetLines__c> budgetLinesList = new List<BudgetLines__c>();
        budgetLinesList = [SELECT BudgetActual__c,BudgetAvailable__c,BudgetCategory__c,BudgetCommitment__c,
                            BudgetConsumptionType__c,BudgetUtilized__c,CreatedById,CreatedDate,ERPBudgetActual__c,
                            ERPBudgetAvailable__c,ERPBudgetCommitment__c,ERPBudgetUtilized__c,Id,Name,
                            OriginalBudget__c,ProjectName__c,TaskID__c,TaskName__c,TaskNumber__c,
                            TotalBudget__c FROM BudgetLines__c WHERE ProjectName__c IN:projectBudgetId Order By ProjectName__c];
        return budgetLinesList;
    }


    @AuraEnabled(cacheable=true)
    public static ProjectBudgetWrapper getAvailableProjectBudgetJSON(Id projectBudgetId){
    
        Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = getAvailableProjectBudget(new Set<Id>{projectBudgetId});
        
        if(projectSalesOrderMap !=null && projectSalesOrderMap.containsKey(projectBudgetId)){
            return projectSalesOrderMap.get(projectBudgetId) ;
        }
        return null ;
        
    }


    /*
    * Check budget availability for the projects
    */
    public static Map<Id,ProjectBudgetWrapper> getAvailableProjectBudget(Set<Id> projectBudgetIds){

        Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = new Map<Id,ProjectBudgetWrapper>();

        for(BudgetLines__c budgetLine : BudgetLinesService.getAllBudgetLines(projectBudgetIds)){
            Id projectId = budgetLine.ProjectName__c ;
            ProjectBudgetWrapper budgetWrapper = (projectSalesOrderMap.containsKey(projectId) ? projectSalesOrderMap.get(projectId) : new ProjectBudgetWrapper());

            Decimal totalAmount = budgetLine.TotalBudget__c ;
            Decimal utilizedAmount = budgetLine.ERPBudgetUtilized__c ;
            Decimal availableAmount = budgetLine.ERPBudgetAvailable__c ;

            if(budgetLine.BudgetCategory__c == CONSTANTS.BUDGET_SALES_SUPPORT_BUCKET){
                budgetWrapper.utilizedSalesSupportBucket = (budgetWrapper.utilizedSalesSupportBucket !=null ? budgetWrapper.utilizedSalesSupportBucket : 0) + utilizedAmount ;
                budgetWrapper.availableSalesSupportBucket = (budgetWrapper.availableSalesSupportBucket !=null ? budgetWrapper.availableSalesSupportBucket : 0) + availableAmount ;
                budgetWrapper.totalSalesSupportBucket = (budgetWrapper.totalSalesSupportBucket !=null ? budgetWrapper.totalSalesSupportBucket : 0) + totalAmount;
            }
                    
            if(budgetLine.BudgetCategory__c == CONSTANTS.BUDGET_DISCOUNT_REBATE_BUCKET){
                budgetWrapper.utilizedDiscountandRebateBucket = (budgetWrapper.utilizedDiscountandRebateBucket !=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) + utilizedAmount ;
                budgetWrapper.availableDiscountandRebateBucket = (budgetWrapper.availableDiscountandRebateBucket !=null ? budgetWrapper.availableDiscountandRebateBucket : 0) + availableAmount ;
                budgetWrapper.totalDiscountandRebateBucket = (budgetWrapper.totalDiscountandRebateBucket !=null ? budgetWrapper.totalDiscountandRebateBucket : 0) + totalAmount;
            }   

            if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_DISCOUNT || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_DISCOUNT){
                budgetWrapper.discountAmount = (budgetWrapper.discountAmount !=null ? budgetWrapper.discountAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalDiscountAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableDiscountAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_SUBSIDY || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_SUBSIDY){
                budgetWrapper.mortgageSubsidy = (budgetWrapper.mortgageSubsidy !=null ? budgetWrapper.mortgageSubsidy : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalmortgageSubsidy = budgetLine.TotalBudget__c ;
                budgetWrapper.availablemortgageSubsidy = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_ADMFEE || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_ADMFEE){
                budgetWrapper.ADMWaiverFee = (budgetWrapper.ADMWaiverFee !=null ? budgetWrapper.ADMWaiverFee : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalADMWaiverFee = budgetLine.TotalBudget__c ;
                budgetWrapper.availableADMWaiverFee = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_DARNA || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_DARNA){
                budgetWrapper.darnaLoyalty = (budgetWrapper.darnaLoyalty !=null ? budgetWrapper.darnaLoyalty : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalDarnaLoyalty = budgetLine.TotalBudget__c ;
                budgetWrapper.availableDarnaLoyalty = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_REBATE || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_REBATE){
                budgetWrapper.rebateAmount = (budgetWrapper.rebateAmount !=null ? budgetWrapper.rebateAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalRebateAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableRebateAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_HOME_MAINTENANCE || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_HOME_MAINTENANCE){
                budgetWrapper.homeMaintenanceWaiverFee = (budgetWrapper.homeMaintenanceWaiverFee !=null ? budgetWrapper.homeMaintenanceWaiverFee : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalHomeMaintenanceWaiverFee = budgetLine.TotalBudget__c ;
                budgetWrapper.availableHomeMaintenanceWaiverFee = budgetLine.ERPBudgetAvailable__c ;       
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_SC_WAIVER || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_SC_WAIVER){
                budgetWrapper.SCWaiverAmount = (budgetWrapper.SCWaiverAmount !=null ? budgetWrapper.SCWaiverAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalSCWaiverAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableSCWaiverAmount = budgetLine.ERPBudgetAvailable__c ;   
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_INTERNAL_COMMISSION || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_INTERNAL_COMMISSION){
                budgetWrapper.internalCommissionAmount = (budgetWrapper.internalCommissionAmount !=null ? budgetWrapper.internalCommissionAmount : 0) + budgetLine.ERPBudgetUtilized__c; 
                budgetWrapper.totalInternalCommissionAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableInternalCommissionAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_EXTERNAL_COMMISSION || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_EXTERNAL_COMMISSION){
                budgetWrapper.externalCommissionAmount = (budgetWrapper.externalCommissionAmount !=null ? budgetWrapper.externalCommissionAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalExternalCommissionAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableExternalCommissionAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.Name ==  CONSTANTS.BUDGET_LINE_OTHER || budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_OTHER){
                budgetWrapper.otherSalesSupportAmount = (budgetWrapper.otherSalesSupportAmount !=null ? budgetWrapper.otherSalesSupportAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalOtherSalesSupportAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableOtherSalesSupportAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_PAYMENT_PROVISION){
                budgetWrapper.utilizedPaymentProvisionAmount = (budgetWrapper.utilizedPaymentProvisionAmount !=null ? budgetWrapper.utilizedPaymentProvisionAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalPaymentProvisionAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availablePaymentProvisionAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            else if(budgetLine.TaskNumber__c == CONSTANTS.BUDGET_TASK_FORFEITED_CASH){
                budgetWrapper.utilizedForfeitedAmount = (budgetWrapper.utilizedForfeitedAmount !=null ? budgetWrapper.utilizedForfeitedAmount : 0) + budgetLine.ERPBudgetUtilized__c;
                budgetWrapper.totalForfeitedAmount = budgetLine.TotalBudget__c ;
                budgetWrapper.availableForfeitedAmount = budgetLine.ERPBudgetAvailable__c ;
            }
            
            projectSalesOrderMap.put(projectId,budgetWrapper);
        }

        System.debug(projectSalesOrderMap+'**Project Budget**'+projectSalesOrderMap.keySet());
        
        for(AggregateResult aggRes : SalesOrderService.getSalesOrdersBookedToday(projectBudgetIds)){
            Id projectId = (aggRes.get('ProjectBudget__c')!=null ? (Id) aggRes.get('ProjectBudget__c') : null );
            System.debug('**ProjectBudget**'+projectId);
            if(projectId !=null && projectBudgetIds.contains(projectId)){
                ProjectBudgetWrapper budgetWrapper = (projectSalesOrderMap.containsKey(projectId) ? projectSalesOrderMap.get(projectId) : new ProjectBudgetWrapper());
                Decimal utilizedAmount = 0 ;
                if(aggRes.get('discount')!=null || aggRes.get('rebateAmount')!=null){
                    if(aggRes.get('discount')!=null){
                        Decimal discountAmount = (Decimal)aggRes.get('discount') ;
                        budgetWrapper.discountAmount = (budgetWrapper.discountAmount !=null ? budgetWrapper.discountAmount : 0) + discountAmount;
                        budgetWrapper.availableDiscountAmount = (budgetWrapper.availableDiscountAmount !=null ? budgetWrapper.availableDiscountAmount : 0) - discountAmount;
                        utilizedAmount = utilizedAmount + discountAmount ;
                    }
                    if(aggRes.get('rebateAmount')!=null){
                        Decimal rebateAmount = (Decimal)aggRes.get('rebateAmount') ;
                        budgetWrapper.rebateAmount = (budgetWrapper.rebateAmount !=null ? budgetWrapper.rebateAmount : 0) + rebateAmount;
                        budgetWrapper.availableRebateAmount = (budgetWrapper.availableRebateAmount !=null ? budgetWrapper.availableRebateAmount : 0) - rebateAmount;
                        utilizedAmount = utilizedAmount + rebateAmount ;
                    }
                    //------ Update Summary of the Discount & Rebate bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedDiscountandRebateBucket = (budgetWrapper.utilizedDiscountandRebateBucket !=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableDiscountandRebateBucket = (budgetWrapper.availableDiscountandRebateBucket !=null ? budgetWrapper.availableDiscountandRebateBucket : 0) - utilizedAmount ;
                        utilizedAmount = 0 ;
                    }
                }
                if(aggRes.get('subsidyAmount')!=null || aggRes.get('admfee')!=null || aggRes.get('darnaAmount')!=null  || aggRes.get('homemaintenance')!=null || aggRes.get('serviceCharge')!=null || aggRes.get('internalComission')!=null || aggRes.get('externalComission')!=null || aggRes.get('othersupportAmount')!=null){
                    if(aggRes.get('subsidyAmount')!=null){
                        Decimal subsidyAmount = (Decimal)aggRes.get('subsidyAmount') ;
                        budgetWrapper.mortgageSubsidy = (budgetWrapper.mortgageSubsidy !=null ? budgetWrapper.mortgageSubsidy : 0) + subsidyAmount;
                        budgetWrapper.availableMortgageSubsidy = (budgetWrapper.availableMortgageSubsidy !=null ? budgetWrapper.availableMortgageSubsidy : 0) - subsidyAmount;
                        utilizedAmount = utilizedAmount + subsidyAmount ;
                    }
                    if(aggRes.get('admfee')!=null){
                        Decimal ADMWaiverFeeAmount = (Decimal)aggRes.get('admfee') ;
                        budgetWrapper.ADMWaiverFee = (budgetWrapper.ADMWaiverFee !=null ? budgetWrapper.ADMWaiverFee : 0) + ADMWaiverFeeAmount;
                        budgetWrapper.availableADMWaiverFee = (budgetWrapper.availableADMWaiverFee !=null ? budgetWrapper.availableADMWaiverFee : 0) - ADMWaiverFeeAmount;
                        utilizedAmount = utilizedAmount + ADMWaiverFeeAmount ;
                    }
                    if(aggRes.get('darnaAmount')!=null){
                        Decimal darnaLoyaltyAmount = (Decimal)aggRes.get('darnaAmount') ;
                        budgetWrapper.darnaLoyalty = (budgetWrapper.darnaLoyalty !=null ? budgetWrapper.darnaLoyalty : 0) + darnaLoyaltyAmount;
                        budgetWrapper.availableDarnaLoyalty = (budgetWrapper.availableDarnaLoyalty !=null ? budgetWrapper.availableDarnaLoyalty : 0) - darnaLoyaltyAmount;
                        utilizedAmount = utilizedAmount + darnaLoyaltyAmount ;
                    }
                    if(aggRes.get('homemaintenance')!=null){
                        Decimal homemaintenanceAmount = (Decimal)aggRes.get('homemaintenance') ;
                        budgetWrapper.homeMaintenanceWaiverFee = (budgetWrapper.homeMaintenanceWaiverFee !=null ? budgetWrapper.homeMaintenanceWaiverFee : 0) + homemaintenanceAmount;
                        budgetWrapper.availableHomeMaintenanceWaiverFee = (budgetWrapper.availableHomeMaintenanceWaiverFee !=null ? budgetWrapper.availableHomeMaintenanceWaiverFee : 0) - homemaintenanceAmount;
                        utilizedAmount = utilizedAmount + homemaintenanceAmount ;
                    }
                    if(aggRes.get('serviceCharge')!=null){
                        Decimal SCWaiverAmount = (Decimal)aggRes.get('serviceCharge') ;
                        budgetWrapper.SCWaiverAmount = (budgetWrapper.SCWaiverAmount !=null ? budgetWrapper.SCWaiverAmount : 0) + SCWaiverAmount;
                        budgetWrapper.availableSCWaiverAmount = (budgetWrapper.availableSCWaiverAmount !=null ? budgetWrapper.availableSCWaiverAmount : 0) - SCWaiverAmount;
                        utilizedAmount = utilizedAmount + SCWaiverAmount ;
                    }
                    if(aggRes.get('internalComission')!=null){
                        Decimal internalComissionAmount = (Decimal)aggRes.get('internalComission') ;
                        budgetWrapper.internalCommissionAmount = (budgetWrapper.internalCommissionAmount !=null ? budgetWrapper.internalCommissionAmount : 0) + internalComissionAmount;
                        budgetWrapper.availableInternalCommissionAmount = (budgetWrapper.availableInternalCommissionAmount !=null ? budgetWrapper.availableInternalCommissionAmount : 0) - internalComissionAmount;
                        utilizedAmount = utilizedAmount + internalComissionAmount ;
                        
                    }
                    if(aggRes.get('externalComission')!=null){
                        Decimal externalComissionAmount = (Decimal)aggRes.get('externalComission') ;
                        budgetWrapper.externalCommissionAmount = (budgetWrapper.externalCommissionAmount !=null ? budgetWrapper.externalCommissionAmount : 0) + externalComissionAmount;
                        budgetWrapper.availableExternalCommissionAmount = (budgetWrapper.availableExternalCommissionAmount !=null ? budgetWrapper.availableExternalCommissionAmount : 0) - externalComissionAmount;
                        utilizedAmount = utilizedAmount + externalComissionAmount ;       
                    }
                    if(aggRes.get('othersupportAmount')!=null){
                        Decimal othersupportAmount = (Decimal)aggRes.get('othersupportAmount') ;
                        budgetWrapper.otherSalesSupportAmount = (budgetWrapper.otherSalesSupportAmount !=null ? budgetWrapper.otherSalesSupportAmount : 0) + othersupportAmount;
                        budgetWrapper.availableOtherSalesSupportAmount = (budgetWrapper.availableOtherSalesSupportAmount !=null ? budgetWrapper.availableOtherSalesSupportAmount : 0) - othersupportAmount;
                        utilizedAmount = utilizedAmount + othersupportAmount ;
                        
                    }
                     //------ Update Summary of the Sales Support Bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedSalesSupportBucket = (budgetWrapper.utilizedSalesSupportBucket !=null ? budgetWrapper.utilizedSalesSupportBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableSalesSupportBucket = (budgetWrapper.availableSalesSupportBucket !=null ? budgetWrapper.availableSalesSupportBucket : 0) - utilizedAmount ;
                    }
                } 
                projectSalesOrderMap.put(projectId,budgetWrapper);
            }   
        }
        for(AggregateResult aggRes : SalesOrderService.getSalesOrdersCancelledToday(projectBudgetIds)){
            Id projectId = (aggRes.get('ProjectBudget__c')!=null ? (Id) aggRes.get('ProjectBudget__c') : null );
            System.debug('**ProjectBudget**'+projectId);
            if(projectId !=null && projectBudgetIds.contains(projectId)){
                ProjectBudgetWrapper budgetWrapper = (projectSalesOrderMap.containsKey(projectId) ? projectSalesOrderMap.get(projectId) : new ProjectBudgetWrapper());
                Decimal utilizedAmount = 0 ;
                if(aggRes.get('discount')!=null || aggRes.get('rebateAmount')!=null){
                    if(aggRes.get('discount')!=null){
                        Decimal discountAmount = (Decimal)aggRes.get('discount') ;
                        budgetWrapper.discountAmount = (budgetWrapper.discountAmount !=null ? budgetWrapper.discountAmount : 0) - discountAmount;
                        budgetWrapper.availableDiscountAmount = (budgetWrapper.availableDiscountAmount !=null ? budgetWrapper.availableDiscountAmount : 0) + discountAmount;
                        utilizedAmount = utilizedAmount + discountAmount ;
                    }
                    if(aggRes.get('rebateAmount')!=null){
                        Decimal rebateAmount = (Decimal)aggRes.get('rebateAmount') ;
                        budgetWrapper.rebateAmount = (budgetWrapper.rebateAmount !=null ? budgetWrapper.rebateAmount : 0) - rebateAmount;
                        budgetWrapper.availableRebateAmount = (budgetWrapper.availableRebateAmount !=null ? budgetWrapper.availableRebateAmount : 0) + rebateAmount;
                        utilizedAmount = utilizedAmount + rebateAmount ;
                    }
                    //------ Update Summary of the Discount & Rebate bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedDiscountandRebateBucket = (budgetWrapper.utilizedDiscountandRebateBucket !=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) - utilizedAmount ;
                        budgetWrapper.availableDiscountandRebateBucket = (budgetWrapper.availableDiscountandRebateBucket !=null ? budgetWrapper.availableDiscountandRebateBucket : 0) + utilizedAmount ;
                        utilizedAmount = 0 ;
                    }
                }
                if(aggRes.get('subsidyAmount')!=null || aggRes.get('admfee')!=null || aggRes.get('darnaAmount')!=null  || aggRes.get('homemaintenance')!=null || aggRes.get('serviceCharge')!=null || aggRes.get('internalComission')!=null || aggRes.get('externalComission')!=null || aggRes.get('othersupportAmount')!=null){
                    if(aggRes.get('subsidyAmount')!=null){
                        Decimal subsidyAmount = (Decimal)aggRes.get('subsidyAmount') ;
                        budgetWrapper.mortgageSubsidy = (budgetWrapper.mortgageSubsidy !=null ? budgetWrapper.mortgageSubsidy : 0) - subsidyAmount;
                        budgetWrapper.availableMortgageSubsidy = (budgetWrapper.availableMortgageSubsidy !=null ? budgetWrapper.availableMortgageSubsidy : 0) + subsidyAmount;
                        utilizedAmount = utilizedAmount + subsidyAmount ;
                    }
                    if(aggRes.get('admfee')!=null){
                        Decimal ADMWaiverFeeAmount = (Decimal)aggRes.get('admfee') ;
                        budgetWrapper.ADMWaiverFee = (budgetWrapper.ADMWaiverFee !=null ? budgetWrapper.ADMWaiverFee : 0) - ADMWaiverFeeAmount;
                        budgetWrapper.availableADMWaiverFee = (budgetWrapper.availableADMWaiverFee !=null ? budgetWrapper.availableADMWaiverFee : 0) + ADMWaiverFeeAmount;
                        utilizedAmount = utilizedAmount + ADMWaiverFeeAmount ;
                    }
                    if(aggRes.get('darnaAmount')!=null){
                        Decimal darnaLoyaltyAmount = (Decimal)aggRes.get('darnaAmount') ;
                        budgetWrapper.darnaLoyalty = (budgetWrapper.darnaLoyalty !=null ? budgetWrapper.darnaLoyalty : 0) - darnaLoyaltyAmount;
                        budgetWrapper.availableDarnaLoyalty = (budgetWrapper.availableDarnaLoyalty !=null ? budgetWrapper.availableDarnaLoyalty : 0) + darnaLoyaltyAmount;
                        utilizedAmount = utilizedAmount + darnaLoyaltyAmount ;
                    }
                    if(aggRes.get('homemaintenance')!=null){
                        Decimal homemaintenanceAmount = (Decimal)aggRes.get('homemaintenance') ;
                        budgetWrapper.homeMaintenanceWaiverFee = (budgetWrapper.homeMaintenanceWaiverFee !=null ? budgetWrapper.homeMaintenanceWaiverFee : 0) - homemaintenanceAmount;
                        budgetWrapper.availableHomeMaintenanceWaiverFee = (budgetWrapper.availableHomeMaintenanceWaiverFee !=null ? budgetWrapper.availableHomeMaintenanceWaiverFee : 0) + homemaintenanceAmount;
                        utilizedAmount = utilizedAmount + homemaintenanceAmount ;
                    }
                    if(aggRes.get('serviceCharge')!=null){
                        Decimal SCWaiverAmount = (Decimal)aggRes.get('serviceCharge') ;
                        budgetWrapper.SCWaiverAmount = (budgetWrapper.SCWaiverAmount !=null ? budgetWrapper.SCWaiverAmount : 0) - SCWaiverAmount;
                        budgetWrapper.availableSCWaiverAmount = (budgetWrapper.availableSCWaiverAmount !=null ? budgetWrapper.availableSCWaiverAmount : 0) + SCWaiverAmount;
                        utilizedAmount = utilizedAmount + SCWaiverAmount ;
                    }
                    if(aggRes.get('internalComission')!=null){
                        Decimal internalComissionAmount = (Decimal)aggRes.get('internalComission') ;
                        budgetWrapper.internalCommissionAmount = (budgetWrapper.internalCommissionAmount !=null ? budgetWrapper.internalCommissionAmount : 0) - internalComissionAmount;
                        budgetWrapper.availableInternalCommissionAmount = (budgetWrapper.availableInternalCommissionAmount !=null ? budgetWrapper.availableInternalCommissionAmount : 0) + internalComissionAmount;
                        utilizedAmount = utilizedAmount + internalComissionAmount ;
                        
                    }
                    if(aggRes.get('externalComission')!=null){
                        Decimal externalComissionAmount = (Decimal)aggRes.get('externalComission') ;
                        budgetWrapper.externalCommissionAmount = (budgetWrapper.externalCommissionAmount !=null ? budgetWrapper.externalCommissionAmount : 0) - externalComissionAmount;
                        budgetWrapper.availableExternalCommissionAmount = (budgetWrapper.availableExternalCommissionAmount !=null ? budgetWrapper.availableExternalCommissionAmount : 0) + externalComissionAmount;
                        utilizedAmount = utilizedAmount + externalComissionAmount ;       
                    }
                    if(aggRes.get('othersupportAmount')!=null){
                        Decimal othersupportAmount = (Decimal)aggRes.get('othersupportAmount') ;
                        budgetWrapper.otherSalesSupportAmount = (budgetWrapper.otherSalesSupportAmount !=null ? budgetWrapper.otherSalesSupportAmount : 0) - othersupportAmount;
                        budgetWrapper.availableOtherSalesSupportAmount = (budgetWrapper.availableOtherSalesSupportAmount !=null ? budgetWrapper.availableOtherSalesSupportAmount : 0) + othersupportAmount;
                        utilizedAmount = utilizedAmount + othersupportAmount ;
                        
                    }
                     //------ Update Summary of the Sales Support Bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedSalesSupportBucket = (budgetWrapper.utilizedSalesSupportBucket !=null ? budgetWrapper.utilizedSalesSupportBucket : 0) - utilizedAmount ;
                        budgetWrapper.availableSalesSupportBucket = (budgetWrapper.availableSalesSupportBucket !=null ? budgetWrapper.availableSalesSupportBucket : 0) + utilizedAmount ;
                    }
                } 
                projectSalesOrderMap.put(projectId,budgetWrapper);
            }   
        }
        System.debug(projectSalesOrderMap+'**Project Budget**'+projectSalesOrderMap.keySet());
        return projectSalesOrderMap ; 
    }


    /*
    * Check budget availability for the projects
    
    public static Map<Id,ProjectBudgetWrapper> checkAvailableProjectBudget(Set<Id> projectBudgetIds,Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper){

        Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = getAvailableProjectBudget(projectBudgetIds);

        for(Unit__c unitRecord : unitPaymentPlanWrapper.keySet()){
            SalesOfferUtility.PaymentPlanWrapper paymentPlanWrapper = unitPaymentPlanWrapper.get(unitRecord);
            ProjectBudgetWrapper budgetWrapper = projectSalesOrderMap.containsKey(unitRecord.ProjectBudget__c) ? projectSalesOrderMap.get(unitRecord.ProjectBudget__c) : new ProjectBudgetWrapper() ;
            budgetWrapper.isBudgetAvailable = false ;
            if(paymentPlanWrapper !=null && budgetWrapper.totalSalesSupportBucket !=null && budgetWrapper.totalDiscountandRebateBucket !=null){
                if(paymentPlanWrapper.rebateAmount !=null){
                    Decimal utilizedAmount = paymentPlanWrapper.rebateAmount ;
                    budgetWrapper.rebateAmount = (budgetWrapper.rebateAmount !=null ? budgetWrapper.rebateAmount : 0) + utilizedAmount;
                    budgetWrapper.availableRebateAmount = (budgetWrapper.availableRebateAmount !=null ? budgetWrapper.availableRebateAmount : 0) - utilizedAmount;
                    //------ Update Summary of the Discount & Rebate bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedDiscountandRebateBucket = (budgetWrapper.utilizedDiscountandRebateBucket !=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableDiscountandRebateBucket = (budgetWrapper.availableDiscountandRebateBucket !=null ? budgetWrapper.availableDiscountandRebateBucket : 0) - utilizedAmount ;
                        //------Verify the summaries to allow the Sales Order Creation
                        budgetWrapper.isBudgetAvailable = budgetWrapper.totalDiscountandRebateBucket > (budgetWrapper.utilizedDiscountandRebateBucket + budgetWrapper.availableDiscountandRebateBucket) ? true : false;
                    }
                } 
            }
            if(paymentPlanWrapper.admFeeWaiverAmount !=null || paymentPlanWrapper.serviceChargeAmount!=null ||paymentPlanWrapper.homeMaintenanceWaiverFee!=null || paymentPlanWrapper.darnaAmount!=null || paymentPlanWrapper.externalComissionAmount!=null || paymentPlanWrapper.internalComissionAmount!=null || paymentPlanWrapper.mortgageSubsidy!=null || paymentPlanWrapper.otherSalesSupportAmount!=null){
                    Decimal utilizedAmount = 0 ;
                    if(paymentPlanWrapper.admFeeWaiverAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.admFeeWaiverAmount ;
                        budgetWrapper.ADMWaiverFee = (budgetWrapper.ADMWaiverFee !=null ? budgetWrapper.ADMWaiverFee : 0) + paymentPlanWrapper.admFeeWaiverAmount;
                        budgetWrapper.availableADMWaiverFee = (budgetWrapper.availableADMWaiverFee !=null ? budgetWrapper.availableADMWaiverFee : 0) - paymentPlanWrapper.admFeeWaiverAmount;
                    }
                    if(paymentPlanWrapper.mortgageSubsidy !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.mortgageSubsidy ;
                        budgetWrapper.mortgageSubsidy = (budgetWrapper.mortgageSubsidy !=null ? budgetWrapper.mortgageSubsidy : 0) + paymentPlanWrapper.mortgageSubsidy;
                        budgetWrapper.availableMortgageSubsidy = (budgetWrapper.availableMortgageSubsidy !=null ? budgetWrapper.availableMortgageSubsidy : 0) - paymentPlanWrapper.mortgageSubsidy;
                    }
                    if(paymentPlanWrapper.serviceChargeAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.serviceChargeAmount ;
                        budgetWrapper.SCWaiverAmount = (budgetWrapper.SCWaiverAmount !=null ? budgetWrapper.SCWaiverAmount : 0) + paymentPlanWrapper.serviceChargeAmount;
                        budgetWrapper.availableSCWaiverAmount = (budgetWrapper.availableSCWaiverAmount !=null ? budgetWrapper.availableSCWaiverAmount : 0) - paymentPlanWrapper.serviceChargeAmount;
                    }
                    if(paymentPlanWrapper.homeMaintenanceWaiverFee !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.homeMaintenanceWaiverFee ;
                        budgetWrapper.homeMaintenanceWaiverFee = (budgetWrapper.homeMaintenanceWaiverFee !=null ? budgetWrapper.homeMaintenanceWaiverFee : 0) + paymentPlanWrapper.homeMaintenanceWaiverFee;
                        budgetWrapper.availableHomeMaintenanceWaiverFee = (budgetWrapper.availableHomeMaintenanceWaiverFee !=null ? budgetWrapper.availableHomeMaintenanceWaiverFee : 0) - paymentPlanWrapper.homeMaintenanceWaiverFee;
                    }
                    if(paymentPlanWrapper.darnaAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.darnaAmount ;
                        budgetWrapper.darnaLoyalty = (budgetWrapper.darnaLoyalty !=null ? budgetWrapper.darnaLoyalty : 0) + paymentPlanWrapper.darnaAmount;
                        budgetWrapper.availableDarnaLoyalty = (budgetWrapper.availableDarnaLoyalty !=null ? budgetWrapper.availableDarnaLoyalty : 0) - paymentPlanWrapper.darnaAmount;
                    }
                    if(paymentPlanWrapper.externalComissionAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.externalComissionAmount ;
                        budgetWrapper.externalCommissionAmount = (budgetWrapper.externalCommissionAmount !=null ? budgetWrapper.externalCommissionAmount : 0) + paymentPlanWrapper.externalComissionAmount;
                        budgetWrapper.availableExternalCommissionAmount = (budgetWrapper.availableExternalCommissionAmount !=null ? budgetWrapper.availableExternalCommissionAmount : 0) - paymentPlanWrapper.externalComissionAmount;
                    }
                    if(paymentPlanWrapper.internalComissionAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.internalComissionAmount ;
                        budgetWrapper.internalCommissionAmount = (budgetWrapper.internalCommissionAmount !=null ? budgetWrapper.internalCommissionAmount : 0) + paymentPlanWrapper.internalComissionAmount;
                        budgetWrapper.availableInternalCommissionAmount = (budgetWrapper.availableInternalCommissionAmount !=null ? budgetWrapper.availableInternalCommissionAmount : 0) - paymentPlanWrapper.internalComissionAmount;
                    }
                    if(paymentPlanWrapper.otherSalesSupportAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.otherSalesSupportAmount ;
                        budgetWrapper.otherSalesSupportAmount = (budgetWrapper.otherSalesSupportAmount !=null ? budgetWrapper.otherSalesSupportAmount : 0) + paymentPlanWrapper.otherSalesSupportAmount;
                        budgetWrapper.availableOtherSalesSupportAmount = (budgetWrapper.availableOtherSalesSupportAmount !=null ? budgetWrapper.availableOtherSalesSupportAmount : 0) - paymentPlanWrapper.otherSalesSupportAmount;
                        
                    }
                    //------ Update Summary of the Sales Support Bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedSalesSupportBucket = (budgetWrapper.utilizedSalesSupportBucket !=null ? budgetWrapper.utilizedSalesSupportBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableSalesSupportBucket = (budgetWrapper.availableSalesSupportBucket !=null ? budgetWrapper.availableSalesSupportBucket : 0) - utilizedAmount ;
                        //------Verify the summaries to allow the Sales Order Creation
                        budgetWrapper.isBudgetAvailable = budgetWrapper.totalSalesSupportBucket > (budgetWrapper.utilizedSalesSupportBucket + budgetWrapper.availableSalesSupportBucket) ? true : false;
                    } 
            } 
        }
        return projectSalesOrderMap  ;
    }
    */

    /*
    * Check budget availability for the projects
   */
    public static Map<Id,ProjectBudgetWrapper> checkAvailableProjectBudget(Set<Id> projectBudgetIds,Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper){

        Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = getAvailableProjectBudget(projectBudgetIds);

        for(Unit__c unitRecord : unitPaymentPlanWrapper.keySet()){
            SalesOfferUtility.PaymentPlanWrapper paymentPlanWrapper = unitPaymentPlanWrapper.get(unitRecord);
            ProjectBudgetWrapper budgetWrapper = projectSalesOrderMap.containsKey(unitRecord.ProjectBudget__c) ? projectSalesOrderMap.get(unitRecord.ProjectBudget__c) : new ProjectBudgetWrapper() ;
            //budgetWrapper.isBudgetAvailable = false ;
            System.debug(budgetWrapper.totalDiscountandRebateBucket+'**Before Discount Budget**'+budgetWrapper.utilizedDiscountandRebateBucket+'**Available**'+budgetWrapper.availableDiscountandRebateBucket);
            System.debug(budgetWrapper.totalSalesSupportBucket+'**Before Sales Support Budget**'+budgetWrapper.utilizedSalesSupportBucket+'**Available**'+budgetWrapper.availableSalesSupportBucket);
            if(paymentPlanWrapper !=null && budgetWrapper.totalSalesSupportBucket !=null && budgetWrapper.totalDiscountandRebateBucket !=null){
                if(paymentPlanWrapper.rebateAmount !=null || paymentPlanWrapper.discountAmount !=null){
                    Decimal utilizedAmount = 0;
                    if(paymentPlanWrapper.rebateAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.rebateAmount ;
                        budgetWrapper.rebateAmount = (budgetWrapper.rebateAmount !=null ? budgetWrapper.rebateAmount : 0) + utilizedAmount;
                        budgetWrapper.availableRebateAmount = (budgetWrapper.availableRebateAmount !=null ? budgetWrapper.availableRebateAmount : 0) - utilizedAmount;
                    }
                    if(paymentPlanWrapper.discountAmount !=null){
                        System.debug(paymentPlanWrapper.discountAmount+'**Discount Amount**');
                        utilizedAmount =utilizedAmount + paymentPlanWrapper.discountAmount ;
                        budgetWrapper.discountAmount = (budgetWrapper.discountAmount !=null ? budgetWrapper.discountAmount : 0) + utilizedAmount;
                        budgetWrapper.availableDiscountAmount = (budgetWrapper.availableDiscountAmount !=null ? budgetWrapper.availableDiscountAmount : 0) - utilizedAmount;
                    }
                    //------ Update Summary of the Discount & Rebate bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedDiscountandRebateBucket = (budgetWrapper.utilizedDiscountandRebateBucket !=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableDiscountandRebateBucket = (budgetWrapper.availableDiscountandRebateBucket !=null ? budgetWrapper.availableDiscountandRebateBucket : 0) - utilizedAmount ;
                        
                    }
                }  
            }
            if(paymentPlanWrapper.admFeeWaiverAmount !=null || paymentPlanWrapper.serviceChargeAmount!=null ||paymentPlanWrapper.homeMaintenanceWaiverFee!=null || paymentPlanWrapper.darnaAmount!=null || paymentPlanWrapper.externalComissionAmount!=null || paymentPlanWrapper.internalComissionAmount!=null || paymentPlanWrapper.mortgageSubsidy!=null || paymentPlanWrapper.otherSalesSupportAmount!=null){
                    Decimal utilizedAmount = 0 ;
                    if(paymentPlanWrapper.admFeeWaiverAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.admFeeWaiverAmount ;
                        budgetWrapper.ADMWaiverFee = (budgetWrapper.ADMWaiverFee !=null ? budgetWrapper.ADMWaiverFee : 0) + paymentPlanWrapper.admFeeWaiverAmount;
                        budgetWrapper.availableADMWaiverFee = (budgetWrapper.availableADMWaiverFee !=null ? budgetWrapper.availableADMWaiverFee : 0) - paymentPlanWrapper.admFeeWaiverAmount;
                    }
                    if(paymentPlanWrapper.mortgageSubsidy !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.mortgageSubsidy ;
                        budgetWrapper.mortgageSubsidy = (budgetWrapper.mortgageSubsidy !=null ? budgetWrapper.mortgageSubsidy : 0) + paymentPlanWrapper.mortgageSubsidy;
                        budgetWrapper.availableMortgageSubsidy = (budgetWrapper.availableMortgageSubsidy !=null ? budgetWrapper.availableMortgageSubsidy : 0) - paymentPlanWrapper.mortgageSubsidy;
                    }
                    if(paymentPlanWrapper.serviceChargeAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.serviceChargeAmount ;
                        budgetWrapper.SCWaiverAmount = (budgetWrapper.SCWaiverAmount !=null ? budgetWrapper.SCWaiverAmount : 0) + paymentPlanWrapper.serviceChargeAmount;
                        budgetWrapper.availableSCWaiverAmount = (budgetWrapper.availableSCWaiverAmount !=null ? budgetWrapper.availableSCWaiverAmount : 0) - paymentPlanWrapper.serviceChargeAmount;
                    }
                    if(paymentPlanWrapper.homeMaintenanceWaiverFee !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.homeMaintenanceWaiverFee ;
                        budgetWrapper.homeMaintenanceWaiverFee = (budgetWrapper.homeMaintenanceWaiverFee !=null ? budgetWrapper.homeMaintenanceWaiverFee : 0) + paymentPlanWrapper.homeMaintenanceWaiverFee;
                        budgetWrapper.availableHomeMaintenanceWaiverFee = (budgetWrapper.availableHomeMaintenanceWaiverFee !=null ? budgetWrapper.availableHomeMaintenanceWaiverFee : 0) - paymentPlanWrapper.homeMaintenanceWaiverFee;
                    }
                    if(paymentPlanWrapper.darnaAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.darnaAmount ;
                        budgetWrapper.darnaLoyalty = (budgetWrapper.darnaLoyalty !=null ? budgetWrapper.darnaLoyalty : 0) + paymentPlanWrapper.darnaAmount;
                        budgetWrapper.availableDarnaLoyalty = (budgetWrapper.availableDarnaLoyalty !=null ? budgetWrapper.availableDarnaLoyalty : 0) - paymentPlanWrapper.darnaAmount;
                    }
                    if(paymentPlanWrapper.externalComissionAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.externalComissionAmount ;
                        budgetWrapper.externalCommissionAmount = (budgetWrapper.externalCommissionAmount !=null ? budgetWrapper.externalCommissionAmount : 0) + paymentPlanWrapper.externalComissionAmount;
                        budgetWrapper.availableExternalCommissionAmount = (budgetWrapper.availableExternalCommissionAmount !=null ? budgetWrapper.availableExternalCommissionAmount : 0) - paymentPlanWrapper.externalComissionAmount;
                    }
                    if(paymentPlanWrapper.internalComissionAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.internalComissionAmount ;
                        budgetWrapper.internalCommissionAmount = (budgetWrapper.internalCommissionAmount !=null ? budgetWrapper.internalCommissionAmount : 0) + paymentPlanWrapper.internalComissionAmount;
                        budgetWrapper.availableInternalCommissionAmount = (budgetWrapper.availableInternalCommissionAmount !=null ? budgetWrapper.availableInternalCommissionAmount : 0) - paymentPlanWrapper.internalComissionAmount;
                    }
                    if(paymentPlanWrapper.otherSalesSupportAmount !=null){
                        utilizedAmount = utilizedAmount + paymentPlanWrapper.otherSalesSupportAmount ;
                        budgetWrapper.otherSalesSupportAmount = (budgetWrapper.otherSalesSupportAmount !=null ? budgetWrapper.otherSalesSupportAmount : 0) + paymentPlanWrapper.otherSalesSupportAmount;
                        budgetWrapper.availableOtherSalesSupportAmount = (budgetWrapper.availableOtherSalesSupportAmount !=null ? budgetWrapper.availableOtherSalesSupportAmount : 0) - paymentPlanWrapper.otherSalesSupportAmount;
                        
                    }
                    //------ Update Summary of the Sales Support Bucket
                    if(utilizedAmount!=null && utilizedAmount!=0){
                        budgetWrapper.utilizedSalesSupportBucket = (budgetWrapper.utilizedSalesSupportBucket !=null ? budgetWrapper.utilizedSalesSupportBucket : 0) + utilizedAmount ;
                        budgetWrapper.availableSalesSupportBucket = (budgetWrapper.availableSalesSupportBucket !=null ? budgetWrapper.availableSalesSupportBucket : 0) - utilizedAmount ;
                    } 
            } 
        }

        for(Unit__c unitRecord : unitPaymentPlanWrapper.keySet()){
            SalesOfferUtility.PaymentPlanWrapper paymentPlanWrapper = unitPaymentPlanWrapper.get(unitRecord);
            ProjectBudgetWrapper budgetWrapper = projectSalesOrderMap.containsKey(unitRecord.ProjectBudget__c) ? projectSalesOrderMap.get(unitRecord.ProjectBudget__c) : new ProjectBudgetWrapper() ;
            budgetWrapper.isBudgetAvailable = false ;
            System.debug(budgetWrapper.totalDiscountandRebateBucket+'**Discount Budget**'+budgetWrapper.utilizedDiscountandRebateBucket+'**Available**'+budgetWrapper.availableDiscountandRebateBucket);
            System.debug(budgetWrapper.totalSalesSupportBucket+'**Sales Support Budget**'+budgetWrapper.utilizedSalesSupportBucket+'**Available**'+budgetWrapper.availableSalesSupportBucket);
            //------Verify the summaries to allow the Sales Order Creation
            if((paymentPlanWrapper.rebateAmount !=null && paymentPlanWrapper.rebateAmount !=0) || (paymentPlanWrapper.discountAmount !=null && paymentPlanWrapper.discountAmount !=0)) {
                budgetWrapper.isBudgetAvailable = (budgetWrapper.totalDiscountandRebateBucket!=null ? budgetWrapper.totalDiscountandRebateBucket : 0) >= (budgetWrapper.utilizedDiscountandRebateBucket!=null ? budgetWrapper.utilizedDiscountandRebateBucket : 0) ? true : false;
            }else
                budgetWrapper.isBudgetAvailable = true ;
            System.debug('isBudgetAvailable ? '+budgetWrapper.isBudgetAvailable);
            //------Verify the summaries to allow the Sales Order Creation
            if(budgetWrapper.isBudgetAvailable)
                budgetWrapper.isBudgetAvailable = budgetWrapper.totalSalesSupportBucket >= (budgetWrapper.utilizedSalesSupportBucket !=null ?budgetWrapper.utilizedSalesSupportBucket : 0 ) ? true : false;
        }

        return projectSalesOrderMap  ;
    }
    
    
}