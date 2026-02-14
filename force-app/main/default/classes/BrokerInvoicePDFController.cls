/**********************************************************************************************************************
* Name               : BrokerInvoicePDFController                                                        
* Description        : Class to displaythe proker Invoice
* Usage              : BrokerInvoicePDF VF Page (Used in Portal)                                                     
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public with sharing class BrokerInvoicePDFController{
    public CommissionLineItem__c commissionRecord {get; set;}
    public integer VAT {get; set;}
    public string renderAsVal {get; set;}
    public string unitName {get; set;}
    public Boolean brokerNameFromProject {get; set;}
    //public string ss {get; set;}
    
    /**
    * BrokerInvoicePDFController
    *
    * Constructor to initialize data
    *
    */
    public BrokerInvoicePDFController(){
        brokerNameFromProject = true;
        VAT = 0;
        for(Constant__mdt tempRec : [select id, ConstantValue__c from Constant__mdt where DeveloperName=:Constants.VAT]){
            VAT=Integer.valueOf(tempRec.ConstantValue__c);
        }
        String invoiceId = ApexPages.currentPage().getParameters().get('invoiceId');
        renderAsVal = ApexPages.currentPage().getParameters().get('renderVal') ;
        //renderAsVal = 'pdf';// (renderAsVal!=null && renderAsVal!='' && renderAsVal=='true')?'pdf':'';
        string fileName='Download';
        if(String.isNotBlank(invoiceId)){
            unitName='';
            list<CommissionLineItem__c> recordList=[select id,InvoiceReferenceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name,InvoiceDate__c, InvoiceNumber__c, Status__c, InstalmentNumber__c,
                                                    BrokerAgency__r.UAEVATRegisterNumber__c,OrderDate__c,SalesOrder__r.Name,SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, CommissionAmountWithVAT__c,
                                                    SalesOrder__r.Opportunity__r.Account.Name,SalesOrder__r.Opportunity__r.Contact__r.Name, CommissionPercentage__c, SalesOrder__r.NetAmount__c, SalesOrder__r.ExternalCommissionAmount__c,CommissionAmount__c,
                                                    BrokerAgency__r.SwiftCode__c,BrokerAgency__r.IBANNumber__c,BrokerAgency__r.BankName__c,BrokerAgency__r.BranchAddress__c,
                                                    BrokerAgency__r.CurrencyISOCOde,BrokerAgency__r.BankCountry__c,BrokerAgency__r.BankAccountNumber__c,
                                                    Frmla_Broker_invoice_Bill_To_Name__c, Frmla_Broker_invoice_TRN_Number__c,
                                                    Frmla_Broker_invoice_Bill_To_Address_1__c, Frmla_Broker_invoice_Bill_To_Address_2__c,
                                                    Frmla_Broker_invoice_Bill_To_Address_3__c
                                                    FROM 
                                                    CommissionLineItem__c 
                                                    WHERE
                                                    Id = :invoiceId WITH SECURITY_ENFORCED limit 1];
            if(!recordList.isEmpty()){ 
                commissionRecord = recordList[0];
                brokerNameFromProject = String.isNotBlank(commissionRecord.Frmla_Broker_invoice_Bill_To_Name__c);//SS_SAL_841
                fileName=commissionRecord.SalesOrder__r.Name+'_'+commissionRecord.InstalmentNumber__c+'_'+commissionRecord.InvoiceNumber__c;
                VAT = (recordList[0].BrokerAgency__r.UAEVATRegisterNumber__c !=null) ? VAT :0;
                unitName = recordList[0].SalesOrder__r.Unit__r.Name ; 
                if(unitName.length()>18) { 
                    unitName = unitName.left(18)+'<br />'+unitName.substring(18);
                }
            }
        }
        if(renderAsVal=='pdf'){ Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename='+fileName+'.pdf');
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static string regenerateBrokerInvoice(Id recordId)
    {
        System.debug('Received RecordId:'+recordId);
        string messageToReturn = Constants.SUCCESS_MESSAGE;
        //All CLI Ids to be added..
        Set<Id> Ids=new  Set<Id>();
        Ids.add(recordId);
        
        ContentDocCLIBatch batch = new ContentDocCLIBatch(Ids);
        Database.executeBatch(batch, 1);
        
        return messageToReturn;
    }
    
}