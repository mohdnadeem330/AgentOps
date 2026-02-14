/**********************************************************************************************************************
* Name               : BrokerMarketingReimbursementController                                                        
* Description        : Class to display the Broker Marketing Reimbursement Invoice
* Usage              : BrokerMarketingReimbursementPDF VF Page (Used in Portal)  
                       This class is covered BrokerMarketingReimbursementControllTest test class                                                   
                                                
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0         msarfaraj@aldar.com     23/04/2025      Initial Draft       
******************************************************************************************************************/
public class BrokerMarketingReimbursementController {

    public BrokerRequest__c brokerRequest {get; set;}
    public string renderAsVal {get; set;}

    public BrokerMarketingReimbursementController (){
        brokerRequest = new BrokerRequest__c();
        String brokerRequestId = ApexPages.currentPage().getParameters().get('brokerRequestId');
        renderAsVal = ApexPages.currentPage().getParameters().get('renderVal');

        string fileName = 'Download';
        if(String.isNotBlank(brokerRequestId)){
            brokerRequest = [SELECT Id, Name, ApprovalStatus__c, InvoiceDate__c, InvoiceAmount__c, TotalAmount__c, TaxAmount__c,
                            InvoiceStatus__c, AgencyName__r.Name, AgencyName__r.UAEVATRegisterNumber__c, AgencyName__r.BankAccountNumber__c,
                            AgencyName__r.IBANNumber__c, AgencyName__r.CurrencyISOCode, AgencyName__r.SwiftCode__c, AgencyName__r.BankName__c,
                            AgencyName__r.BranchAddress__c, AgencyName__r.BankCountry__c, AgencyName__r.BeneficiaryName__c, AgencyName__r.AgencyRegion__c,
                            AgencyName__r.BillingStreet, AgencyName__r.BillingCity, AgencyName__r.BillingState, AgencyName__r.BillingPostalCode,
                            AgencyName__r.BillingCountry, RequestQuarter__c, RequestYear__c, Description__c FROM BrokerRequest__c Where Id = :brokerRequestId];
        }
        if(renderAsVal=='pdf'){ Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename='+fileName+'.pdf');
        }
    }
}