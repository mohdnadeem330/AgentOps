public with sharing class BuildingSectionMappingService {
   
    @AuraEnabled(cacheable=false)
    public static void insertBuildingSectionMapping(List<InstallmentLineChanges__c> installmentLineChangesList){
        List<BuildingSectionMapping__c> buildingSectionMappingList = new List<BuildingSectionMapping__c>();

        List<PaymentPlan__c> paymentPlans = PaymentPlanService.lastCreatedPaymentPlanDetails(installmentLineChangesList[0].BookingMemo__c);

        for (PaymentPlan__c paymentPlan : paymentPlans) {
            
            BuildingSectionMapping__c buildingSectionMappingRecord = new BuildingSectionMapping__c();
            buildingSectionMappingRecord.BuildingSectionName__c = paymentPlan.Unit__r.BuildingSectionName__c;
            buildingSectionMappingRecord.PaymentPlan__c = paymentPlan.Id;
            buildingSectionMappingList.Add(buildingSectionMappingRecord);
            
        }

        insert buildingSectionMappingList;
    }

}