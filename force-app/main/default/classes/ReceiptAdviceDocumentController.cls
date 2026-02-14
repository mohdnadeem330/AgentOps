public with sharing class ReceiptAdviceDocumentController {

    public static ReceiptAdvice receiptAdviceRecord		{set;get;}
    /*
    * Get Installment & Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=true)
    public static void getSalesOrderReceipts(){
        try {
			String Owners = '';
            List<JointOwner__c> jointownerdetail = new List<JointOwner__c>(); 
            Id salesOrderId = ApexPages.currentPage().getParameters().get('id'); 
           
            System.debug('**salesOrderId**'+salesOrderId);

            //------ Query Sales Order and related records
            SalesOrder__c salesOrderDetail = [SELECT Id,Name,Opportunity__c,Unit__r.Project__r.Name_of_Seller__c,Unit__r.Project__r.Name,Unit__r.Name,Account__r.Name,Account__r.AccountNumber,ADMPercentage__c,(SELECT Id, InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c 
            FROM InstallmentLines__r),(SELECT Id, InstallmentLine__c,ReceiptAcknowledgement__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.ReferenceNumber__c,AmountApplied__c,InstallmentNumberOrChargeType__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.BankName__c,InstallmentLine__r.installmentPercentage__c FROM ReceiptAllocations__r WHERE Unapply__c=false AND AmountApplied__c > 1 AND ReceiptStatus__c!='Link Sent' ORDER BY InstallmentNumberOrChargeType__c) FROM SalesOrder__c WHERE Id=:salesOrderId];

            String fileName = 'Receipt Advice: '+salesOrderDetail.Name;
            Owners = salesOrderDetail.Account__r.Name;
            jointownerdetail = [select id, Account__r.name from JointOwner__c where SalesOrder__c = :SalesOrderId ];
            if(!jointownerdetail.isEmpty()){
                for(JointOwner__c jo : jointownerdetail){
                    Owners += ' and '+ jo.Account__r.Name;
                }
            }
            system.debug('JointOwners : '+Owners);
            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');
            
            receiptAdviceRecord = new ReceiptAdvice();
            receiptAdviceRecord.projectName = salesOrderDetail.Unit__r.Project__r.Name ;
            receiptAdviceRecord.Nameofsellrer = salesOrderDetail.Unit__r.Project__r.Name_of_Seller__c ;
            receiptAdviceRecord.unitNumber = salesOrderDetail.Unit__r.Name ;
            receiptAdviceRecord.customerName = Owners;		//salesOrderDetail.Account__r.Name ;
            receiptAdviceRecord.customerNumber = salesOrderDetail.Account__r.AccountNumber ;
            receiptAdviceRecord.installmentDetails = new List<InstallmentDetail>();
            receiptAdviceRecord.prepatedDate = Date.Today();
            receiptAdviceRecord.preparedBy = UserInfo.getName();

            Decimal totalAmount = 0 ;

            for(ReceiptAllocation__c receiptAllocationRec : salesOrderDetail.ReceiptAllocations__r){
                InstallmentDetail installmentRec = new InstallmentDetail();
                installmentRec.installmentNumber = receiptAllocationRec.InstallmentNumberOrChargeType__c ;
                installmentRec.amount = receiptAllocationRec.AmountApplied__c ;
                if(receiptAllocationRec.InstallmentLine__c !=null)
                    installmentRec.installmentPercentage = receiptAllocationRec.InstallmentLine__r.installmentPercentage__c ;
                else
                    installmentRec.installmentPercentage = salesOrderDetail.ADMPercentage__c ;
                installmentRec.referenceNumber = receiptAllocationRec.ReceiptAcknowledgement__r.ReferenceNumber__c ;
                installmentRec.receiptDate = receiptAllocationRec.ReceiptAcknowledgement__r.MaturityDate__c ;
                installmentRec.bankName = receiptAllocationRec.ReceiptAcknowledgement__r.BankName__c ;
                totalAmount = totalAmount + installmentRec.amount ;
                totalAmount = totalAmount.setScale(2);
                receiptAdviceRecord.installmentDetails.add(installmentRec);
            }

            if(totalAmount>0){
                receiptAdviceRecord.amountInWords = Utilities.amountInWords(totalAmount,Constants.UAE_CURRENCY_UNIT,Constants.UAE_CURRENCY_SUBUNIT);
                System.debug('**salesOrderId**'+receiptAdviceRecord.amountInWords);
                receiptAdviceRecord.totalAmount = totalAmount ;
            }

        } catch (Exception e) {
            throw e;
        }
    }

    /*
    * Get Installment or Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=true)
    public static void getInstallmentOrOtherChargesReceipt(){
        try {
            Id salesOrderId = ApexPages.currentPage().getParameters().get('salesOrderId');
            Id paymentId = ApexPages.currentPage().getParameters().get('paymentId');

            String subQuery = '';
            String whareCaluse = '';
            if (((Id)paymentId).getSObjectType() == InstallmentLines__c.getSObjectType()) {
                subQuery = ' (SELECT Id, Name, InstallmentNumber__c, InstallmentAmount__c, SalesOrder__r.UnitNumber__c FROM InstallmentLines__r WHERE Id = \'' + paymentId + '\'), ';
                whareCaluse = ' AND InstallmentLine__c = \'' + paymentId + '\'';
            }  else if (((Id)paymentId).getSObjectType() == Order.getSObjectType()) {
                subQuery = ' (SELECT Id, Name, OrderNumber, TotalAmount, Sales_Order__r.UnitNumber__c FROM Orders__r WHERE Id = \'' + paymentId + '\'), ';
                whareCaluse = ' AND Order__c = \'' + paymentId + '\'';
            }else {
                subQuery = ' (SELECT Id, Name, SubType__c, TypeOfCharge__c, Amount__c, SalesOrder__r.UnitNumber__c FROM SalesOrdersOtherCharges__r WHERE Id = \'' + paymentId + '\'), ';
                whareCaluse = ' AND SalesOrderOtherCharges__c = \'' + paymentId + '\'';
            }
            
            //------ Query Sales Order and related records
            String query = 'SELECT Id, Name, Opportunity__c, Unit__r.Project__r.Name, Unit__r.Name, Account__r.Name, Account__r.AccountNumber, Account__r.AccountNumber__c, ADMPercentage__c, ';
            query += subQuery;
            if(((Id)paymentId).getSObjectType() == Order.getSObjectType()){
                query +=' (SELECT PaymentType__c, Status__c,ReceiptNumber__c,ClearedDate__c,Amount__c,ReferenceNumber__c,BankName__c,Name  FROM Payments__r Where Status__c = \'Cleared\' '+whareCaluse+')';
            }else{
            	query += ' (SELECT Id, ReceiptAcknowledgement__c, InstallmentLine__c, SalesOrderOtherCharges__c, ReceiptAcknowledgement__r.ReferenceNumber__c, AmountApplied__c, InstallmentNumberOrChargeType__c, ReceiptAcknowledgement__r.BankName__c, ReceiptAcknowledgement__r.MaturityDate__c, InstallmentLine__r.installmentPercentage__c FROM ReceiptAllocations__r WHERE Unapply__c = false AND AmountApplied__c > 1 and ReceiptStatus__c!=\'Link Sent\' ' + whareCaluse + ' ORDER BY InstallmentNumberOrChargeType__c) ';
            }
            query += ' FROM SalesOrder__c WHERE Id = \'' + salesOrderId + '\'';
            SalesOrder__c salesOrder = Database.query(query);
            

            String Owners = salesOrder.Account__r.Name;
            List<JointOwner__c> jointownerdetail = new List<JointOwner__c>();
            if(SalesOrderId!= null &&  !test.isRunningTest()){
             jointownerdetail = [SELECT Id, Account__r.Name FROM JointOwner__c WHERE SalesOrder__c =: SalesOrderId];
            }
            if (!jointownerdetail.isEmpty()) {
                for (JointOwner__c jo: jointownerdetail) {
                    Owners += ' and ' + jo.Account__r.Name;
                }
            }
            System.debug('Owners : ' + Owners);

            String fileName = '';
            Boolean isParkingReceipt = false;
            String parkingRefId = '';
            Decimal amount = 0;
            List<Order> relatedOrders = new List<Order>();
            if (paymentId.getSObjectType() == InstallmentLines__c.getSObjectType()) {
                InstallmentLines__c line = salesOrder.InstallmentLines__r[0];
                amount = line.InstallmentAmount__c;
                fileName = 'Receipt-' + line.SalesOrder__r.UnitNumber__c + '-' + (CustomerAPIConstants.INSTALLMENT_PAYMENT + ' ' + line.InstallmentNumber__c).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
            } /* Added by Neelesh */
            else if(((Id)paymentId).getSObjectType() == Order.getSObjectType()) {
                system.debug('Payment ID inside Orderobject' );
                // InstallmentLines__c line = CustomerServiceUtility.getInstallmentLineDetail(' (Id = \'' + paymentId + '\') ')[0];
                relatedOrders = [
                    SELECT Id, OrderNumber, TotalAmount,  ParkingAsset__r.Ref_ID__c, Sales_Order__r.UnitNumber__c,
                    (SELECT Id, Name, PaymentType__c, Status__c,ReceiptNumber__c,ClearedDate__c,Amount__c, ReferenceNumber__c, BankName__c  FROM Receipt_Acknowledgements__r Where Status__c = 'Cleared')
                    FROM Order 
                    WHERE Id =: paymentId
                    // Sales_Order__c = :line.SalesOrder_
                    //     ORDER BY CreatedDate DESC 
                    //     LIMIT 1
                ];
                isParkingReceipt = true;
                String unitNumber = (relatedOrders[0].Sales_Order__r != null) ? relatedOrders[0].Sales_Order__r.UnitNumber__c : ' ';
                String orderNumber = relatedOrders.isEmpty() ? 'Unknown' : relatedOrders[0].OrderNumber;
                parkingRefId = relatedOrders.isEmpty() || relatedOrders[0].ParkingAsset__r == null  ? 'N/A' : String.valueOf(relatedOrders[0].ParkingAsset__r.Ref_ID__c);
                //fileName = 'Receipt-' + unitNumber + '-' + (CustomerAPIConstants.PARKING_PAYMENT + ' ' + orderNumber).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
                salesOrderId = relatedOrders[0].Sales_Order__c;
                system.debug('Line 56 order object :salesOrderId ' + salesOrderId);
                // (((Id)paymentId).getSObjectType() == Order.getSObjectType()) {
                //Order order = salesOrder.Orders__r[0]; 
                amount = relatedOrders[0].TotalAmount;
                fileName = 'Receipt-' + relatedOrders[0].Sales_Order__r.UnitNumber__c + '-' + (CustomerAPIConstants.PARKING_PAYMENT + ' ' + relatedOrders[0].orderNumber).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
                /* ended  by Neelesh */
            } else {
                SalesOrderOtherCharges__c otherCharge = salesOrder.SalesOrdersOtherCharges__r[0];
                amount = otherCharge.Amount__c;
                fileName = 'Receipt-' + otherCharge.SalesOrder__r.UnitNumber__c + '-' + (String.isNotBlank(otherCharge.SubType__c) ? otherCharge.TypeOfCharge__c + ' - ' + otherCharge.SubType__c : otherCharge.TypeOfCharge__c).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
            }
            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');

            receiptAdviceRecord = new ReceiptAdvice();
            receiptAdviceRecord.projectName = salesOrder.Unit__r.Project__r.Name;
            receiptAdviceRecord.unitNumber = salesOrder.Unit__r.Name;
            receiptAdviceRecord.customerName = Owners;
            receiptAdviceRecord.customerNumber = salesOrder.Account__r.AccountNumber__c;
            receiptAdviceRecord.amount = amount;
            receiptAdviceRecord.installmentDetails = new List<InstallmentDetail>();
            receiptAdviceRecord.receiptDetails = new List<ReceiptDetail>();
            receiptAdviceRecord.prepatedDate = Date.Today();
            receiptAdviceRecord.preparedBy = UserInfo.getName();
            receiptAdviceRecord.isParking = isParkingReceipt;
            receiptAdviceRecord.parkingNumber = parkingRefId;
            Decimal totalAmount = 0 ;
            if(relatedOrders.size() > 0){
                    for(ReceiptAcknowledgement__c rec : relatedOrders[0].Receipt_Acknowledgements__r){
                        if(relatedOrders[0].Receipt_Acknowledgements__r != null){
                           ReceiptDetail rd = new ReceiptDetail();
                            rd.receiptNumber = rec.Name;
                            rd.ReferenceNumber = rec.ReferenceNumber__c;
                            rd.receiptpDate = rec.ClearedDate__c;
                            rd.receiptAmount = rec.Amount__c;
                            rd.Status = rec.Status__c;
                            rd.BankName = rec.BankName__c;
                             totalAmount = totalAmount + rec.Amount__c;
                            totalAmount = totalAmount.setScale(2);
                            receiptAdviceRecord.receiptDetails.add(rd); 
                        }
                }
            }
            
            
            for (ReceiptAllocation__c receiptAllocationRec : salesOrder.ReceiptAllocations__r) {
                InstallmentDetail installmentRec = new InstallmentDetail();
                installmentRec.installmentNumber = receiptAllocationRec.InstallmentNumberOrChargeType__c;
                installmentRec.amount = receiptAllocationRec.AmountApplied__c;
                if (receiptAllocationRec.InstallmentLine__c != null) {
                    installmentRec.installmentPercentage = receiptAllocationRec.InstallmentLine__r.installmentPercentage__c;
                } else {
                    installmentRec.installmentPercentage = salesOrder.ADMPercentage__c;
                }
                installmentRec.referenceNumber = receiptAllocationRec.ReceiptAcknowledgement__r.ReferenceNumber__c;
                installmentRec.receiptDate = receiptAllocationRec.ReceiptAcknowledgement__r.MaturityDate__c;
                installmentRec.bankName = receiptAllocationRec.ReceiptAcknowledgement__r.BankName__c;
                totalAmount = totalAmount + installmentRec.amount;
                totalAmount = totalAmount.setScale(2);
                receiptAdviceRecord.installmentDetails.add(installmentRec);
            }

            if (totalAmount > 0) {
                receiptAdviceRecord.amountInWords = Utilities.amountInWords(totalAmount,Constants.UAE_CURRENCY_UNIT,Constants.UAE_CURRENCY_SUBUNIT);
                receiptAdviceRecord.totalAmount = totalAmount ;
            }
            system.debug('####receiptAdviceRecord: '+receiptAdviceRecord);
        } catch (Exception e) {
            throw e;
        }
    }

    public class ReceiptAdvice{

        public String projectName       {set;get;}
        public String Nameofsellrer     {set;get;}
        public String unitNumber        {set;get;}
        public String customerName      {set;get;}
        public String customerNumber    {set;get;}
        public List<InstallmentDetail> installmentDetails {set;get;}
        public List<ReceiptDetail> receiptDetails{set;get;}
        public Decimal amount           {set;get;}
        public Decimal totalAmount      {set;get;}
        public String amountInWords     {set;get;}
        public String preparedBy        {set;get;}
        public Date prepatedDate        {set;get;}
        public Boolean isParking        {set;get;}
        public String parkingNumber        {set;get;}

    }
    public class ReceiptDetail{
        
        public string receiptNumber {set;get;}
        public String ReferenceNumber {set;get;}
        public Date receiptpDate {set;get;}
        public Decimal receiptAmount {set;get;}
        public String Status {set;get;}
        public String BankName{set;get;}
        
    }

    public class InstallmentDetail{
        public String installmentNumber         {set;get;}
        public Decimal installmentPercentage    {set;get;}
        public String referenceNumber           {set;get;}
        public Date receiptDate                 {set;get;}
        public String bankName                  {set;get;}
        public Decimal amount                   {set;get;}
    }
}