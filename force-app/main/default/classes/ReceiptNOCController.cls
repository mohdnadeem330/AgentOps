public class ReceiptNOCController {
    
    public static String unitNumber		{set;get;}
    public static List<NocDetails> displayList  {get;set;}

    /*
* Get Installment & Sales Order Details by record Id
*/

    @AuraEnabled(cacheable=true)
    public static Boolean getReceiptDetails(String salesOrderId){
        List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
        receiptList = [SELECT Id,Amount__c,Account__c,Account__r.Name,MaturityDate__c,
            BankName__c, RecievedFromAccount__r.name,SalesOrder__r.Unit__r.Name,
            ReferenceNumber__c, RecievedFromAccount__c
           FROM ReceiptAcknowledgement__c 
           WHERE RecievedFromAccount__c!=null AND SalesOrder__c=:salesOrderId];
           if(receiptList.size() > 0){
                return true;
           }else{
                return false;
           }
    }

    @AuraEnabled(cacheable=true)
    public static void getSalesOrderReceipts(){
        try {
            
            Id salesOrderId = ApexPages.currentPage().getParameters().get('id'); 
            
            System.debug('**salesOrderId**'+salesOrderId);
            displayList = new List<NocDetails>();
            //------ Query Sales Order and related records
            Map<String,NocDetails> receiptByBenificiary = new Map<String,NocDetails>();
            for(ReceiptAcknowledgement__c receiptRecord : [SELECT Id,Amount__c,Account__c,Account__r.Name,MaturityDate__c,
            BankName__c, RecievedFromAccount__r.name,SalesOrder__r.Unit__r.Name,
            ReferenceNumber__c, RecievedFromAccount__c
           FROM ReceiptAcknowledgement__c
                WHERE RecievedFromAccount__c!=null AND SalesOrder__c=:salesOrderId ]){
                    if(receiptByBenificiary.containsKey(receiptRecord.RecievedFromAccount__r.name)){
                        List<InstallmentDetail> tempInstallments = new List<InstallmentDetail>();
                        NocDetails temp = new NocDetails();
                        temp = receiptByBenificiary.get(receiptRecord.RecievedFromAccount__r.name);
                        tempInstallments = temp.receiptDetails;
                        InstallmentDetail instll = new InstallmentDetail();
                        instll.bankName = receiptRecord.BankName__c;
                        instll.chequeNumber = receiptRecord.ReferenceNumber__c;
                        instll.amount = receiptRecord.Amount__c;
                        instll.chequeDate = receiptRecord.MaturityDate__c;
                        tempInstallments.add(instll);
                        
                        temp.receiptDetails = tempInstallments;
                        receiptByBenificiary.put(receiptRecord.RecievedFromAccount__r.name,temp);
                    }else{
                        NocDetails ra = new NocDetails();
                        ra.customerName = receiptRecord.Account__r.Name;
                        ra.unitNumber = receiptRecord.SalesOrder__r.Unit__r.Name;
                        ra.benificiaryName = receiptRecord.RecievedFromAccount__r.name;
                        unitNumber = ra.unitNumber;
                        ra.prepatedDate = Date.Today();
                        List<InstallmentDetail> tempInstallments = new List<InstallmentDetail>();
                        InstallmentDetail instll = new InstallmentDetail();
                        instll.bankName = receiptRecord.BankName__c;
                        instll.chequeNumber = receiptRecord.ReferenceNumber__c;
                        instll.amount = receiptRecord.Amount__c;
                        instll.chequeDate = receiptRecord.MaturityDate__c;
                        tempInstallments.add(instll);
                        ra.receiptDetails = tempInstallments;
                        receiptByBenificiary.put(receiptRecord.RecievedFromAccount__r.Name,ra);
                    }
                    
                }
                displayList = receiptByBenificiary.values();
                system.debug('displayList '+displayList);
                String fileName = 'Receipt NOC: '+unitNumber;
                //+salesOrderDetail.Name;

                Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');
        } catch (Exception e) {
            throw e;
        }
    }
    
    public class NocDetails{
        public String unitNumber        {set;get;}
        public String customerName      {set;get;}
        public String benificiaryName      {set;get;}
        public List<InstallmentDetail> receiptDetails {set;get;}
        public Date prepatedDate        {set;get;}
    }
    
    public class InstallmentDetail{
        public String chequeNumber  {set;get;}
        public Date chequeDate  {set;get;}
        public String bankName      {set;get;}
        public Decimal amount  {set;get;}


    }
}