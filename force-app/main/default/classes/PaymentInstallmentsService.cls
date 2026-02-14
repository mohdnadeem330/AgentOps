/**********************************************************************************************************************
* Name               : PaymentInstallmentsService                                                        
* Description        : This class method to create Payment plan for the memo
* Usage              : 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class PaymentInstallmentsService {
    @AuraEnabled(cacheable=false)
    public static void insertPaymentInstallments(List<InstallmentLineChanges__c> installmentLineChangesList){
        List<PaymentInstallments__c> paymentInstallmentsList = new List<PaymentInstallments__c>();

        for (Integer i = 0; i < installmentLineChangesList.size(); i++) {
            
            String paymentPlanId = PaymentPlanService.lastCreatedIdPaymentPlan(installmentLineChangesList[i].BookingMemo__c,installmentLineChangesList[i].Unit__c);

            PaymentInstallments__c paymentInstallmentsRecord = new PaymentInstallments__c();
            paymentInstallmentsRecord.InstallmentNumber__c = installmentLineChangesList[i].InstallmentNumber__c;
            paymentInstallmentsRecord.InstallmentPercentage__c = installmentLineChangesList[i].ProposedInstallmentPercentage__c;
            paymentInstallmentsRecord.InstallmentDate__c = installmentLineChangesList[i].ProposedInstallmentDate__c;
            paymentInstallmentsRecord.Description__c = installmentLineChangesList[i].Description__c;
            paymentInstallmentsRecord.PaymentPlan__c = paymentPlanId;
            paymentInstallmentsList.Add(paymentInstallmentsRecord);
        }

        insert paymentInstallmentsList;
    }
}