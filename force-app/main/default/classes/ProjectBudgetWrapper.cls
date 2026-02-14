public class ProjectBudgetWrapper {
	 @AuraEnabled
    public Boolean isBudgetAvailable ; //true to proceed with booking
    //---- Avaialble Budget
    @AuraEnabled
    public Decimal availablediscountAmount ;
    @AuraEnabled
    public Decimal availablemortgageSubsidy ;
    @AuraEnabled
    public Decimal availableADMWaiverFee ;
    @AuraEnabled
    public Decimal availabledarnaLoyalty ;
    @AuraEnabled
    public Decimal availablerebateAmount ;
    @AuraEnabled
    public Decimal availablehomeMaintenanceWaiverFee ;
    @AuraEnabled
    public Decimal availableSCWaiverAmount ;
    @AuraEnabled
    public Decimal availableinternalCommissionAmount ;
    @AuraEnabled
    public Decimal availableexternalCommissionAmount ;
    @AuraEnabled
    public Decimal availableotherSalesSupportAmount ;
    @AuraEnabled
    public Decimal availablePaymentProvisionAmount ;
    @AuraEnabled
    public Decimal availableForfeitedAmount ;
    //---- Utlizied Budget
    @AuraEnabled
    public Decimal discountAmount ;
    @AuraEnabled
    public Decimal mortgageSubsidy ;
    @AuraEnabled
    public Decimal ADMWaiverFee ;
    @AuraEnabled
    public Decimal darnaLoyalty ;
    @AuraEnabled
    public Decimal rebateAmount ;
    @AuraEnabled
    public Decimal homeMaintenanceWaiverFee ;
    @AuraEnabled
    public Decimal SCWaiverAmount ;
    @AuraEnabled
    public Decimal internalCommissionAmount ;
    @AuraEnabled
    public Decimal externalCommissionAmount ;
    @AuraEnabled
    public Decimal otherSalesSupportAmount ;
    @AuraEnabled
    public Decimal utilizedPaymentProvisionAmount ;
    @AuraEnabled
    public Decimal utilizedForfeitedAmount ;
    //---- Total Budget
    @AuraEnabled
    public Decimal totaldiscountAmount ;
    @AuraEnabled
    public Decimal totalmortgageSubsidy ;
    @AuraEnabled
    public Decimal totalADMWaiverFee ;
    @AuraEnabled
    public Decimal totaldarnaLoyalty ;
    @AuraEnabled
    public Decimal totalRebateAmount ;
    @AuraEnabled
    public Decimal totalhomeMaintenanceWaiverFee ;
    @AuraEnabled
    public Decimal totalSCWaiverAmount ;
    @AuraEnabled
    public Decimal totalinternalCommissionAmount ;
    @AuraEnabled
    public Decimal totalexternalCommissionAmount ;
    @AuraEnabled
    public Decimal totalotherSalesSupportAmount ;
    //---- Summary Varibales for Budget
    @AuraEnabled
    public Decimal availableSalesSupportBucket;
    @AuraEnabled
    public Decimal availableDiscountandRebateBucket ;
    @AuraEnabled
    public Decimal utilizedSalesSupportBucket;
    @AuraEnabled
    public Decimal utilizedDiscountandRebateBucket ;
    @AuraEnabled
    public Decimal totalSalesSupportBucket;
    @AuraEnabled
    public Decimal totalDiscountandRebateBucket ;
    @AuraEnabled
    public Decimal totalPaymentProvisionAmount ;
    @AuraEnabled
    public Decimal totalForfeitedAmount ;

}