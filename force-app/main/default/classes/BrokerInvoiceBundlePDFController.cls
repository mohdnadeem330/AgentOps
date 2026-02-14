/**********************************************************************************************************************
* Name               : BrokerInvoiceBundlePDFController                                                        
* Description        : Class to displaythe proker Invoice
* Usage              : BrokerInvoiceBundlePDF VF Page (Used in Portal)                                                     
                                                
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           smanohar@aldar.com     29/08/2023      Initial Draft       
******************************************************************************************************************/
public class BrokerInvoiceBundlePDFController {

    public InvoiceBundle__c invoicerecord {get; set;}
    public String invoiceId {get; set;}
    public List<commissionWrapper> commissionwrapperList{get;set;}
    public List<CommissionLineItem__c> commissionRecordList {get; set;}
    public integer VAT {get; set;}
    public string renderAsVal {get; set;}
    public string unitName {get; set;}
    public Boolean brokerNameFromProject {get; set;}
    
    public class commissionWrapper{
        public String UnitDetails{get;set;}
        public String Property{get;set;}
        public String CustomerName{get;set;}
        public Decimal PurchasePrice{get;set;}
        public Decimal TotalCommission{get;set;}
        public Decimal TotalRate{get;set;}
        public Decimal InvoiceRate{get;set;}
        public Decimal PaidAmount{get;set;}
        public Decimal CommissionAmount{get;set;}
        public Date OrderDate{get;set;}
        
    }
    public BrokerInvoiceBundlePDFController (){
        Set<Id> SalesOderIdSet = new Set<Id>();
        Map<String, Integer> SOPaidCommissionMap = new Map<String, Integer>();
        List<commissionWrapper> commissionwrapList = new List<commissionWrapper>();
        brokerNameFromProject = true;
        VAT = 0;
        for(Constant__mdt tempRec : [select id, ConstantValue__c from Constant__mdt where DeveloperName=:Constants.VAT]){
            VAT=Integer.valueOf(tempRec.ConstantValue__c);
        }
        
    /*    Blob key = Blob.valueOf('1234567890123456');
        system.debug('Decrypted value::'+ApexPages.currentPage().getParameters().get('invoiceId'));
        Blob encodedEncryptedBlob = EncodingUtil.base64Decode(ApexPages.currentPage().getParameters().get('invoiceId'));
        
        system.debug('encodedEncryptedBlob::'+encodedEncryptedBlob);
        
        Blob decrypted = Crypto.decryptWithManagedIV('AES128', key, encodedEncryptedBlob);
        system.debug('decrypted::'+decrypted); */
        String DecryptedValue = ApexPages.currentPage().getParameters().get('invoiceId');
        if(DecryptedValue.contains(' ')){
            DecryptedValue = DecryptedValue.replaceAll(' ', '+');
        }
        system.debug('Decrypted value::'+ApexPages.currentPage().getParameters().get('invoiceId'));
        String invoiceId = EncryptionUtils.decryptString(DecryptedValue);
        system.debug('invoiceId::'+invoiceId);

       // String invoiceId = ApexPages.currentPage().getParameters().get('invoiceId');
        invoiceId = invoiceId;
         renderAsVal = ApexPages.currentPage().getParameters().get('renderVal');
        string fileName='Download';
        if(String.isNotBlank(invoiceId)){
            unitName='';
            InvoiceBundle__c invoiceRec = [SELECT ApprovalStatus__c,
                                           BrokerAgency__c,
                                           BundleName__c,
                                           BundleNumber__c,
                                           BrokerAgency__r.BillingStreet,
                                           BrokerAgency__r.BillingCity,
                                           BrokerAgency__r.BillingState,
                                           BrokerAgency__r.BillingCountry,
                                           BrokerAgency__r.BillingPostalCode,
                                           Id,
                                           InvoiceDate__c,
                                           Name,
                                           TRNNumber__c,
                                           Status__c,
                                           TotalCommissionLineItemCount__c,
                                           TotalNumberofCommission__c,
                                           TotalVATAmount__c,
                                           TotalCommissionAmountWithVAT__c,
                                           TotalCommissionAmount__c,
                                           BrokerAgency__r.UAEVATRegisterNumber__c,
                                           BrokerAgency__r.Name,
                                           BrokerAgency__r.BankAccountNumber__c,
                                           BrokerAgency__r.IBANNumber__c,
                                           BrokerAgency__r.CurrencyISOCode,
                                           BrokerAgency__r.SwiftCode__c,
                                           BrokerAgency__r.BankName__c,
                                           BrokerAgency__r.BranchAddress__c,
                                           BrokerAgency__r.BankCountry__c,
                                           BrokerAgency__r.BeneficiaryName__c,
                                           BrokerAgency__r.AgencyRegion__c,
                                           BrokerinvoiceBillToName__c,
                                           BrokerinvoiceBillToAddress1__c,
                                           BrokerinvoiceBillToAddress2__c,
                                           BrokerinvoiceBillToAddress3__c
                                           FROM InvoiceBundle__c Where Id = :invoiceId];
            
            list<CommissionLineItem__c> recordList=[Select id,InvoiceReferenceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name,InvoiceDate__c, InvoiceNumber__c, Status__c, InstalmentNumber__c,
                                                    BrokerAgency__r.UAEVATRegisterNumber__c,OrderDate__c,SalesOrder__r.Name,SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, CommissionAmountWithVAT__c,
                                                    SalesOrder__r.Opportunity__r.Account.Name,SalesOrder__r.Opportunity__r.Contact__r.Name, CommissionPercentage__c, SalesOrder__r.NetAmount__c, SalesOrder__r.ExternalCommissionAmount__c,CommissionAmount__c,
                                                    BrokerAgency__r.SwiftCode__c,BrokerAgency__r.IBANNumber__c,BrokerAgency__r.BankName__c,BrokerAgency__r.BranchAddress__c,
                                                    BrokerAgency__r.CurrencyISOCOde,BrokerAgency__r.BankCountry__c,BrokerAgency__r.BankAccountNumber__c,Total_External_Commission__c,
                                                    Frmla_Broker_invoice_Bill_To_Name__c, Frmla_Broker_invoice_TRN_Number__c,
                                                    Frmla_Broker_invoice_Bill_To_Address_1__c, Frmla_Broker_invoice_Bill_To_Address_2__c,
                                                    Frmla_Broker_invoice_Bill_To_Address_3__c, InvoiceBundle__c, InvoiceBundle__r.Name, InvoiceBundle__r.BrokerAgency__r.UAEVATRegisterNumber__c
                                                    FROM 
                                                    CommissionLineItem__c 
                                                    WHERE
                                                    InvoiceBundle__c = :invoiceId ];
            
            
            for(CommissionLineItem__c commissionLineItem: recordList){
                SalesOderIdSet.add(commissionLineItem.SalesOrder__c);
            }
            List<AggregateResult> groupResult = [Select SalesOrder__c soId, SUM(CommissionAmount__c)commissionAmount FROM 
                                                 CommissionLineItem__c 
                                                 WHERE SalesOrder__c IN: SalesOderIdSet 
                                                 AND Status__c = 'Paid'
                                                 AND Id NOT in: recordList 
                                                 AND CommissionType__c = 'External' GROUP BY SalesOrder__c];
            for(AggregateResult ar: groupResult){
                SOPaidCommissionMap.put(String.valueOf(ar.get('soId')),Integer.valueOf(ar.get('commissionAmount')));
            }
            
            if(!recordList.isEmpty()){ 
                for(CommissionLineItem__c commissionRecord: recordList){
                    commissionWrapper wrap = new commissionWrapper();
                    String strUnitName = commissionRecord.SalesOrder__r.Unit__r.Name;
                    wrap.UnitDetails = strUnitName.length() >= 20 ? strUnitName.substring(0, 20)+' '+strUnitName.substring(20) : strUnitName;
                    wrap.Property = commissionRecord.SalesOrder__r.ProjectName__c;
                    wrap.CustomerName = commissionRecord.SalesOrder__r.Opportunity__r.Account.Name;
                    wrap.PurchasePrice = commissionRecord.SalesOrder__r.NetAmount__c;
                    wrap.TotalCommission = commissionRecord.SalesOrder__r.ExternalCommissionAmount__c;
                    wrap.TotalRate = (commissionRecord.SalesOrder__r.ExternalCommissionAmount__c*100/commissionRecord.SalesOrder__r.NetAmount__c);
                    wrap.InvoiceRate = (commissionRecord.CommissionAmount__c*100/commissionRecord.SalesOrder__r.NetAmount__c);
                    wrap.PaidAmount = SOPaidCommissionMap.get(commissionRecord.SalesOrder__c) != null ? SOPaidCommissionMap.get(commissionRecord.SalesOrder__c) : 0;
                    wrap.CommissionAmount = commissionRecord.CommissionAmount__c;
                    wrap.OrderDate = commissionRecord.OrderDate__c;
                    commissionwrapList.add(wrap);
                }
                brokerNameFromProject = String.isNotBlank(invoiceRec.BrokerinvoiceBillToName__c);
                commissionwrapperList = commissionwrapList;
                commissionRecordList = recordList;
                invoicerecord = invoiceRec;
                fileName = invoiceRec.Name;
                VAT = (invoiceRec.BrokerAgency__r.UAEVATRegisterNumber__c !=null) ? VAT :0;
            }
        }
        if(renderAsVal=='pdf'){ Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename='+fileName+'.pdf');
        }
    }
}