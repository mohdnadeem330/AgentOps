public class StatementOfAccountModel_STAGING{

    public Date generationDate          {set;get;}
    public String customerAddress       {set;get;}
    public Unit__c unitDetail           {set;get;}
    public String agreementType         {set;get;}
    public SalesOrder__c orderDetail    {set;get;}
    public List<InstallmentDetail> installmentDetails   {set;get;}
    public Decimal totalPercentage                      {set;get;}
    public Decimal totalLPC                             {set;get;}
    public Decimal totalInstallmentAmountDue            {set;get;}
    public Decimal totalAmountDue                       {set;get;}
    public Decimal totalOtherCharge                     {set;get;}
    public Decimal totalUnClearedReceipts               {set;get;}
    public String amountInWordsDue                      {set;get;}
    public List<OtherChargeDetails> otherCharges        {set;get;}
    public String jointOwnerNames                                  {set;get;}
    public List<ReceiptAcknowledgement__c> recievedReceipts        {set;get;}
    public String beneficiaryName                                  {set;get;}
    public String bankAccountNumber                                {set;get;}
    public String bankName                                         {set;get;}
    public String bankBranch                                       {set;get;}
    public String IBAN                                             {set;get;}
    public String swiftCode                                        {set;get;}
    public List<ReceiptAcknowledgement__c> clearedReceipts         {set;get;}
    public List<ReceiptAcknowledgement__c> rebateCreditNotes        {set;get;}

    public StatementOfAccountModel_STAGING(){
        this.generationDate = Date.today();
        this.customerAddress = '';
        this.unitDetail = new Unit__c();
        this.agreementType = '';
        this.orderDetail = new SalesOrder__c();
        this.installmentDetails = new List<InstallmentDetail>();
        this.totalInstallmentAmountDue = 0 ;
        this.totalAmountDue = 0 ;
        this.totalLPC = 0 ;
        this.totalOtherCharge = 0 ;
        this.totalUnClearedReceipts = 0 ;
        this.amountInWordsDue = '';
        this.otherCharges = new List<OtherChargeDetails>();
        this.jointOwnerNames = '';
        this.recievedReceipts = new  List<ReceiptAcknowledgement__c>();
        this.beneficiaryName = '';
        this.bankAccountNumber = '';
        this.bankName = '';
        this.bankBranch = '';
        this.IBAN = '';
        this.swiftCode = '';
        this.clearedReceipts = new  List<ReceiptAcknowledgement__c>();
        this.rebateCreditNotes = new  List<ReceiptAcknowledgement__c>();
        
    } 

    public class OtherChargeDetails{
        public SalesOrderOtherCharges__c orderOtherCharge {set;get;}
        public List<ReceiptAllocation__c> allocationList     {set;get;}
        public Integer rowSpanNo                             {set;get;} 

        public OtherChargeDetails(SalesOrderOtherCharges__c otherChargeRec,List<ReceiptAllocation__c> allocationList){
            this.orderOtherCharge = otherChargeRec ;
            this.rowSpanNo = -1 ;
            if(allocationList!=null && allocationList.size()>0){
                rowSpanNo = allocationList.size() + 1;
                this.allocationList = allocationList ;
            }
        }
    }

    public class InstallmentDetail{
        public Date installmentDate             {set;get;}
        public Decimal installmentNumber        {set;get;}
        public String installmentDescription    {set;get;}
        public Decimal installmentPercentage    {set;get;}
        public String invoiceNumber             {set;get;}
        public Decimal installmentAmount        {set;get;}
        public Decimal pendingAmount            {set;get;}
        public Decimal latePaymentCharge        {set;get;}
        public List<ReceiptAllocation__c> allocationList     {set;get;}
        public Integer rowSpanNo                             {set;get;}

        public InstallmentDetail(InstallmentLines__c installmentLineRec, Decimal latePaymentCharge,List<ReceiptAllocation__c> receiptList){
            this.installmentDate = installmentLineRec.InstallmentDate__c ;
            this.installmentNumber = installmentLineRec.InstallmentNumber__c ;
            this.installmentDescription = installmentLineRec.Description__c ;
            this.installmentPercentage = installmentLineRec.InstallmentPercentage__c ;
            this.invoiceNumber = installmentLineRec.InvoiceNumber__c ;
            this.installmentAmount = installmentLineRec.InstallmentAmount__c ;
            if(String.isNotBlank(installmentLineRec.InvoiceNumber__c)){
                this.pendingAmount = installmentLineRec.OutstandingAmount__c ;
                this.latePaymentCharge = latePaymentCharge ;
            }else{
                this.pendingAmount = null ;
                this.latePaymentCharge = null ;
            }    
            this.rowSpanNo = -1 ;
            if(receiptList!=null && receiptList.size()>0){
                rowSpanNo = receiptList.size() + 1;
                this.allocationList = receiptList ;
            }
            System.debug('**installmentNumber**'+this.installmentNumber+'**rowSpanNo**'+this.rowSpanNo);
        }
    }

}