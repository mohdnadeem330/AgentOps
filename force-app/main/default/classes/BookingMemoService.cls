public with sharing class BookingMemoService {
    @AuraEnabled(cacheable=false)
    public static string createBookingMemo(String relatedOpportunity, String memoHeader, String memoSubject, String memoType, String specialNote) {   
        BookingMemo__c bookingMemoRecord = new BookingMemo__c();
        if (String.isNotBlank(relatedOpportunity)) {
            bookingMemoRecord.RelatedOpportunity__c = relatedOpportunity;
        }
        if (String.isNotBlank(memoType)) {
            bookingMemoRecord.MemoType__c = memoType;
        }
        if (String.isNotBlank(memoSubject)) {
            bookingMemoRecord.MemoSubject__c = memoSubject;
        }
        if (String.isNotBlank(memoHeader)) {
            bookingMemoRecord.MemoHeader__c = memoHeader; 
        }
        if (String.isNotBlank(specialNote)) {
            bookingMemoRecord.SpecialNote__c = specialNote; 
        }
        
        

    insert bookingMemoRecord;
    return bookingMemoRecord.Id;     
  }

  @AuraEnabled(cacheable=false)
  public static String lastCreatedIdBookingMemo() {   
    String lastCreatedId;
    List<BookingMemo__c> records = [select Id from BookingMemo__c order by CreatedDate DESC limit 1];
        if(records.size() > 0)
        {
             lastCreatedId = records[0].Id;
        }
        return lastCreatedId;     
    }

    public static list<BookingMemo__c> getMemoDetails(set<ID> memoIds){
        return [select id,Name,ApprovalProgress__c,ApprovalStatus__c,ApprovalSubStatus__c,ExistingOffer__c,ExistingOffer__r.Name,ExistingPaymentPlan__c,ExistingPaymentPlan__r.Name,LastModifiedApproveStatus__c,MemoHeader__c,MemoSubject__c,MemoType__c,OwnerManger__c,OwnerManger__r.Name,RelatedOpportunity__c,RelatedOpportunity__r.Name,RelatedOpportunityCustomerName__c,SpecialNote__c from BookingMemo__c where id in :memoIds];
    }

    public static list<OffersPromotions__c> getMyOfferDetails(set<ID> memoIds){
        return [select id,Name,BuildingSectionName__c,BuildingSectionName__r.Name,OfferDescription__c,OfferName__c,Project__c,Project__r.Name,Unit__c,Unit__r.Name,(select id,Name,OfferType__c,OfferOn__c,OfferValue__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c from Offers_Lines__r) from OffersPromotions__c where BookingMemo__c in :memoIds and IsActive__c = true /*and OwnerId = :UserInfo.getUserId()*/];
    }
    public static list<PaymentPlan__c> getMyPaymentDetails(set<ID> memoIds){
        return [ select id,Name,CustomerSubType__c,PaymentPlanType__c,Description__c ,Premium__c,RebatePercentage__c,PaymentPlanDiscount__c,Unit__c,Unit__r.Name,StandardFlag__c,BrokerPortalFlag__c,(select id,Name,PaymentPlan__c,InstallmentNumber__c,Description__c,InstallmentPercentage__c,InstallmentDate__c,BrokerPayoutPercentage__c from PaymentInstallments__r ORDER BY InstallmentNumber__c asc) from PaymentPlan__c where /*OwnerId = :UserInfo.getUserId() and*/  IsActive__c =: Constants.PAYMENT_PLAN_ACTIVE_YES and BookingMemo__c in :memoIds];
    }
}