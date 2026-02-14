/*
* Purpose: Construct a Unit Detail Modal for storing information about the selected or available unit.
*/
public class UnitDetailModel {
    public String Id {get; set;}
    public String soId {get; set;}
    public String unitId {get; set;}
    public String accountId {get; set;}
    public String accountName {get; set;}
    public String projectName {get; set;}
    public String unitNo {get; set;}
    public String salesOrderNo {get; set;}
    public Decimal sellingPrice {get; set;}
    public Decimal netAmount {get; set;}
    public Decimal totalInstallmentReceived {get; set;}
    public Decimal totalOutstanding {get; set;}
    public Decimal otherRebateAmount {get; set;}
    public Decimal ADMFeeWaivedAmount {get; set;}
    public Decimal escalationServiceCharge {get; set;}
    public Decimal anticipatedServiceCharges {get; set;}
    public Decimal equityPercent {get; set;}
    public Decimal discountValue {get; set;}
    public Decimal totalNonNegotiableCost {get; set;}
    public Boolean isFullRefund {get; set;}
    public Decimal serviceCharge {get; set;}
    public Decimal districtCooling {get; set;}
    public Decimal ADDCAssumption {get; set;}
    public Decimal legalfeesVAT {get; set;}
    public Decimal additionalForfeitedAmount {get; set;}
    public Decimal totalFutureResaleCost {get; set;}
    public Decimal ADMWaiver {get; set;}
    public Decimal ADMWaiverAmount {get; set;}
    public Decimal rebate {get; set;}
    public Decimal rebateAmount {get; set;}
    public Decimal darna {get; set;}
    public Decimal darnaAmount {get; set;}
    public Decimal salesSupportCost {get; set;}
    public Decimal voucher {get; set;}
    public Decimal SCWaiver {get; set;}
    public Decimal SCWaivedAmount {get; set;}
    public Decimal totalFutureCommission {get; set;}
    public Decimal externalCommission {get; set;}
    public Decimal externalCommissionAmount {get; set;}
    public Decimal internalCommission {get; set;}
    public Decimal internalCommissionAmount {get; set;}
    public Boolean retainedUnit {get; set;}
    public Boolean cancelledUnit {get; set;}
    public Boolean option1 {get; set;}
    public Boolean option2 {get; set;}
    public Boolean option3 {get; set;}
    public Decimal lossCalculation1 {get; set;}
    public Decimal lossCalculation2 {get; set;}
    public Decimal lossCalculation3 {get; set;}
    public Decimal equityRefund1 {get; set;}
    public Decimal equityRefund2 {get; set;}
    public Decimal equityRefund3 {get; set;}
    //Added by Rajat SSR-288
    public Decimal OtherLossCalcutation {get; set;}
    public Boolean option4 {get; set;}
    public Decimal lossCalculation4 {get; set;}
    public Decimal equityRefund4 {get; set;}
    public Decimal totalOtherLossCalculation {get; set;}
    //End
}