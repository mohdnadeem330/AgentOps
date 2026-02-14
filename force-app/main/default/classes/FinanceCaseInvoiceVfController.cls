public class FinanceCaseInvoiceVfController {
    // public String today { get { return System.now()?.formatGMT('EEE, MMM d yyyy'); }}
    public List<Case> invoiceCases {set; get;}


    @testVisible static String caseId;


    public FinanceCaseInvoiceVfController() {
        invoiceCases = new List<Case>();
        caseId = ApexPages.currentPage()?.getParameters()?.get('caseId');

        invoiceCases = [SELECT Id,Case.Unit__r.Name,Parent.CaseNumber,Parent.CreatedDate,CurrencyIsoCode,Disbursement_Date__c,
                        Disbursement_Amount__c,Home_Finance_Facilitator__c,Applicable_Payout_Rate__c,
                        TotalCommissionforAldar__c,Bank_Name__c FROM Case WHERE ParentId =:caseId AND 
                        CaseCategory__c = 'Home Finance'];
    }
}