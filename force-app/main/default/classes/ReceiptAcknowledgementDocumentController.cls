public with sharing class ReceiptAcknowledgementDocumentController {
    //version				owner				date			description
    //1.1					Nasir				20sep2022    	added logic of single receipt print
    public static ReceiptAcknowledgement receiptAcknowledgementRecord		{set;get;}
    
    /*
* Get Installment & Sales Order Details by record Id
*/
    @AuraEnabled(cacheable=true)
    public static void getSalesOrderReceipts(){
        try {
            //Id salesOrderId = ApexPages.currentPage().getParameters().get('id'); 		//1.1 start
            Id RecordId = ApexPages.currentPage().getParameters().get('id'); 			
            String sObjName = RecordId.getSObjectType().getDescribe().getName();
            System.debug('**sObjName**'+sObjName);
            string SalesOrderId;
            string ReceiptAcknowledgementId;
            SalesOrder__c salesOrderDetail = new SalesOrder__c();
            String Owners = '';
            List<JointOwner__c> jointownerdetail = new List<JointOwner__c>(); 
            if (sObjName == 'SalesOrder__c') {											
                //------Onlyif related object is SalesOrder__c
                SalesOrderId = RecordId;
                System.debug('**salesOrderId**'+RecordId);
                salesOrderDetail = [SELECT Id,Name,Opportunity__c,Unit__r.Project__r.Name,Unit__r.Project__r.Name_of_Seller__c,Unit__r.Name,Account__r.Name,Account__r.AccountNumber__c,ADMPercentage__c,(SELECT Id,Name, ReferenceNumber__c,MaturityDate__c,BankName__c,CreatedDate,Account__c,Amount__c,PaymentType__c,ReceiptNumber__c FROM Payments__r WHERE Amount__c > 0 and Status__c != 'Reversed' AND Status__c !='Link Sent' and paymenttype__c != 'Credit Note'
                                                                                                                                                                     ORDER BY CreatedDate) FROM SalesOrder__c WHERE Id=:salesOrderId];
            }
            if (sObjName == 'ReceiptAcknowledgement__c') {								
                //------Onlyif related object is ReceiptAcknowledgment
                ReceiptAcknowledgementId = RecordId;
                ReceiptAcknowledgement__c receiptRecord = [select salesOrder__c from ReceiptAcknowledgement__c where id = :ReceiptAcknowledgementId];
                SalesOrderId = receiptRecord.SalesOrder__c;                
                salesOrderDetail = [SELECT Id,Name,Opportunity__c,Unit__r.Project__r.Name,Unit__r.Project__r.Name_of_Seller__c,Unit__r.Name,Account__r.Name,Account__r.AccountNumber__c,ADMPercentage__c,(SELECT Id,Name, ReferenceNumber__c,MaturityDate__c,BankName__c,CreatedDate,Account__c,Amount__c,PaymentType__c,ReceiptNumber__c FROM Payments__r WHERE Amount__c > 0 and Status__c != 'Reversed' AND Status__c !='Link Sent' and paymenttype__c != 'Credit Note' and id = :ReceiptAcknowledgementId
                                                                                                                                                                     ORDER BY CreatedDate) FROM SalesOrder__c WHERE Id=:receiptRecord.SalesOrder__c];
            }
            Owners = salesOrderDetail.Account__r.Name;
            jointownerdetail = [select id, Account__r.name from JointOwner__c where SalesOrder__c = :SalesOrderId ];
            if(!jointownerdetail.isEmpty()){
                for(JointOwner__c jo : jointownerdetail){
                    Owners += ' and '+ jo.Account__r.Name;
                }
            }
            system.debug('JointOwners : '+Owners);								//1.1
            String fileName = 'Receipt Acknowledgement: '+salesOrderDetail.Name;
            
            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');
            
            receiptAcknowledgementRecord = new ReceiptAcknowledgement();
            receiptAcknowledgementRecord.projectName = salesOrderDetail.Unit__r.Project__r.Name ;
            receiptAcknowledgementRecord.Nameofsellrer = salesOrderDetail.Unit__r.Project__r.Name_of_Seller__c ;
            receiptAcknowledgementRecord.unitNumber = salesOrderDetail.Unit__r.Name ;
            receiptAcknowledgementRecord.customerName = Owners; //salesOrderDetail.Account__r.Name;		//1.1
            receiptAcknowledgementRecord.customerNumber = salesOrderDetail.Account__r.AccountNumber__c ;
            receiptAcknowledgementRecord.receiptDetails = new List<ReceiptDetails>();
            receiptAcknowledgementRecord.prepatedDate = Date.Today();
            receiptAcknowledgementRecord.preparedBy = UserInfo.getName();
            
            Decimal totalAmount = 0 ;
            
            for(ReceiptAcknowledgement__c receiptAckRec : salesOrderDetail.Payments__r){
                ReceiptDetails receiptRec = new ReceiptDetails();
                receiptRec.referenceNumber = receiptAckRec.ReferenceNumber__c ;
                receiptRec.receiptDate = receiptAckRec.MaturityDate__c ;
                receiptRec.bankName = receiptAckRec.BankName__c ;
                receiptRec.amount = receiptAckRec.Amount__c ;
                receiptRec.paymentType = receiptAckRec.PaymentType__c ;
                totalAmount = totalAmount + receiptRec.amount ;
                totalAmount = totalAmount.setScale(2);
                receiptAcknowledgementRecord.receiptDetails.add(receiptRec);
            }
            
            if(totalAmount>0){
                receiptAcknowledgementRecord.amountInWords = Utilities.amountInWords(totalAmount,Constants.UAE_CURRENCY_UNIT,Constants.UAE_CURRENCY_SUBUNIT);
                System.debug('**salesOrderId**'+receiptAcknowledgementRecord.amountInWords);
                receiptAcknowledgementRecord.totalAmount = totalAmount ;
            }
            
        } catch (Exception e) {
            throw e;
        }
    }
    
    public class ReceiptAcknowledgement{
        
        public String projectName       {set;get;}
        public String Nameofsellrer     {set;get;}
        public String unitNumber        {set;get;}
        public String customerName      {set;get;}
        public String customerNumber    {set;get;}
        public List<ReceiptDetails> receiptDetails {set;get;}
        public Decimal totalAmount      {set;get;}
        public String amountInWords     {set;get;}
        public String preparedBy        {set;get;}
        public Date prepatedDate        {set;get;}
        
    }
    
    public class ReceiptDetails{
        public String referenceNumber           {set;get;}
        public Date receiptDate                 {set;get;}
        public String bankName                  {set;get;}
        public Decimal amount                   {set;get;}
        public String paymentType              {set;get;}
    }
}