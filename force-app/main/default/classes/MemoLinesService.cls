public with sharing class MemoLinesService {
    @AuraEnabled(cacheable=false)
    public static MemoLines__c createMemoLines(String existingOffer, String  existingPaymentPlan, String unit, String bookingMemo, String sCWaiverYears, String pMFeeYears, String homeMaintenanceYears, String additionalDiscountAmount, String subsidyAmount, 
    String subsidyPercentage, String discountPercentage, String rebatePercentage, String aDMFeePercentage, String intCommissionPercentage
    , String brokerCommissionPercentage, String additionalDiscountPercentage, String voucherAmount, String voucherName, String membershipType,String membershipAmount ) {
        
        MemoLines__c memoLinesRecord = new MemoLines__c();
        
        if (String.isNotBlank(bookingMemo)) {
            memoLinesRecord.BookingMemo__c = bookingMemo;
        }
        if (String.isNotBlank(unit)) {
            memoLinesRecord.Unit__c = unit;
        }
        if (String.isNotBlank(existingOffer)) {
            memoLinesRecord.ExistingOffer__c = existingOffer;  
        }
        if (String.isNotBlank(existingPaymentPlan)) {
            memoLinesRecord.ExistingPaymentPlan__c = existingPaymentPlan;  
        }
        if (String.isNotBlank(sCWaiverYears)) {
            memoLinesRecord.SCWaiverYears__c = decimal.valueOf(sCWaiverYears);
        }
        if (String.isNotBlank(pMFeeYears)) {
            memoLinesRecord.PMFeeYears__c = decimal.valueOf(pMFeeYears);
        }
        if (String.isNotBlank(homeMaintenanceYears)) {
            memoLinesRecord.HomeMaintenanceYears__c = decimal.valueOf(homeMaintenanceYears);
        }
        if (String.isNotBlank(subsidyPercentage)) {
            memoLinesRecord.SubsidyPercentage__c = decimal.valueOf(subsidyPercentage);
        }
        if (String.isNotBlank(discountPercentage)) {
            memoLinesRecord.DiscountPercentage__c = decimal.valueOf(discountPercentage);
        }
        if (String.isNotBlank(rebatePercentage)) {
            memoLinesRecord.RebatePercentage__c = decimal.valueOf(rebatePercentage);
        }
        if (String.isNotBlank(intCommissionPercentage)) {
            memoLinesRecord.IntCommissionPercentage__c = decimal.valueOf(intCommissionPercentage);
        }
        if (String.isNotBlank(aDMFeePercentage)) {
            memoLinesRecord.ADMFeePercentage__c = decimal.valueOf(aDMFeePercentage);
        }
        if (String.isNotBlank(brokerCommissionPercentage)) {
            memoLinesRecord.BrokerCommissionPercentage__c = decimal.valueOf(brokerCommissionPercentage);
        }
        if (String.isNotBlank(additionalDiscountPercentage)) {
            memoLinesRecord.AdditionalDiscountPercentage__c = decimal.valueOf(additionalDiscountPercentage);
        }
        if (String.isNotBlank(voucherName)) {
            memoLinesRecord.VoucherName__c = voucherName;
        }
        if (String.isNotBlank(voucherAmount)) {
            memoLinesRecord.VoucherAmount__c = decimal.valueOf(voucherAmount);
        }
        if (String.isNotBlank(membershipType)) {
            memoLinesRecord.MembershipType__c = membershipType;
        }
        if (String.isNotBlank(membershipAmount)) {
            memoLinesRecord.MembershipAmount__c = decimal.valueOf(membershipAmount);
        }
        
          
      return memoLinesRecord;     
    }

    @AuraEnabled(cacheable=false)
    public static void insertMemoLines(List<MemoLines__c> memoLinesList, List<InstallmentLineChanges__c> installmentLineChange){
        insert memoLinesList;
        insert installmentLineChange;
    }

    @AuraEnabled(cacheable=false)
    public static List<MemoLines__c> getMemoLinesByBookinMemoId(Id bookingMemoId) {
        List<MemoLines__c> records = [select Id,Unit__c,Unit__r.Project__c,Unit__r.Status__c,SCWaiverYears__c,PMFeeYears__c,HomeMaintenanceYears__c
        ,AdditionalDiscountPercentage__c,BrokerCommissionPercentage__c,ADMFeePercentage__c,BookingMemo__c,
        IntCommissionPercentage__c,RebatePercentage__c,SubsidyPercentage__c,DiscountPercentage__c,RebateAmount__c, DiscountAmount__c from MemoLines__c where BookingMemo__c =: bookingMemoId];
    return records;
    } 
}