public without sharing class QuarterlyInvoicePDFController {
	public CommissionLineItem__c commissionRecord {get; set;}
    public List<CommissionLineItem__c> commissionRecordList {get; set;}
    public Decimal SubTotal {get; set;}
    public Decimal total {get; set;}
    public integer VAT {get; set;}
    public string renderAsVal {get; set;}
    public string unitName {get; set;}
    public Boolean brokerNameFromProject {get; set;}
    public Date invoiceDate{get;set;}
    public String invoiceId{get;set;}
    //public string ss {get; set;}
    
    /**
    * BrokerInvoicePDFController
    *
    * Constructor to initialize data
    *
    */
    public QuarterlyInvoicePDFController(){
        brokerNameFromProject = false;
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
                                                    Frmla_Broker_invoice_Bill_To_Address_3__c,QuarterlyBonusCommission__r.Name,QuarterlyBonusCommission__r.Quarter__c,
                                                    QuarterlyBonusCommission__r.Invoicedate__c,
                                                    QuarterlyBonusCommission__r.Year__c
                                                    FROM 
                                                    CommissionLineItem__c 
                                                    WHERE
                                                    QuarterlyBonusCommission__c  = :invoiceId];
            if(!recordList.isEmpty()){ 
                commissionRecordList = recordList;
                SubTotal = 0;
                total = 0;
                for(CommissionLineItem__c cli: recordList){
                    subTotal = subTotal + cli.CommissionAmount__c;
                    total = total + cli.CommissionAmountWithVAT__c;
                }
                commissionRecord = recordList[0];
                invoiceDate = recordList[0].QuarterlyBonusCommission__r.Invoicedate__c;
                brokerNameFromProject = String.isNotBlank(commissionRecord.Frmla_Broker_invoice_Bill_To_Name__c);//SS_SAL_841
                fileName=commissionRecord.BrokerAgency__r.Name+'_'+commissionRecord.QuarterlyBonusCommission__r.Quarter__c+'_'+commissionRecord.QuarterlyBonusCommission__r.Year__c;
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
}