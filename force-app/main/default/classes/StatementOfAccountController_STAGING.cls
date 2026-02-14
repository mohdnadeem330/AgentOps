public without sharing class StatementOfAccountController_STAGING {
    
    public static StatementOfAccountModel_STAGING statementOfAccount        {set;get;}
    public static String RECEIPT_ADJUSTMENT = 'Adjustment Write Off' ;

     /*
    * Get Installment Lines, Sales Order Other Charges and receipt acknowledgement by Order Id
    */
    @AuraEnabled(cacheable=true)
    public static void getSalesOrderDetails(){
        try {

            Id salesOrderId = ApexPages.currentPage().getParameters().get('id'); 
            Decimal totalLPCWaivedOrPaid = 0 ; 
            Date todayDate = Date.Today();
           
            System.debug('**salesOrderId**'+salesOrderId);

            statementOfAccount = new StatementOfAccountModel_STAGING();
            Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
            Map<Id,List<ReceiptAllocation__c>> installmentAllAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
            Map<Id,List<ReceiptAllocation__c>> otherChargeAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
            Decimal clearedAmountOutstanding = 0 ; 

            LPCService_STAGING.EXCLUDE_LPC_CALCULATION = true ; 
            LPCModel lpcDetail = LPCService_STAGING.getOutstandingLPCforSalesOrder(salesOrderId);
            totalLPCWaivedOrPaid = lpcDetail.totalLPCWaivedOrPaid ;

            //------ Query Sales Order and related records
            SalesOrder__c salesOrderRec = lpcDetail.orderDetail;

            if(String.isBlank(salesOrderRec.MortgageApplicable__c)){
                salesOrderRec.MortgageApplicable__c = 'No';
            }

            System.debug(salesOrderRec+'**Receipts**'+salesOrderRec.ReceiptAllocations__r);

            statementOfAccount.orderDetail = salesOrderRec ; 
            statementOfAccount.generationDate = todayDate ;
            statementOfAccount.unitDetail = salesOrderRec.Unit__r ; 
            statementOfAccount.customerAddress = salesOrderRec.Account__r.BillingStreet + ', ' + salesOrderRec.Account__r.BillingCity + ', ' + salesOrderRec.Account__r.BillingCountry ;  
            statementOfAccount.installmentDetails = new List<StatementOfAccountModel_STAGING.InstallmentDetail>();
            statementOfAccount.totalInstallmentAmountDue = 0 ;
            statementOfAccount.totalAmountDue = 0 ;
            statementOfAccount.totalLPC = 0 ;
            statementOfAccount.totalOtherCharge = 0 ;

            //---- If the Order is booked before BCC then the Virtual or Escrow account as to be used
            if(salesOrderRec.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c ==null || salesOrderRec.BookingDate__c < salesOrderRec.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c){
                statementOfAccount.beneficiaryName = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c : salesOrderRec.Unit__r.Project__r.BeneficiaryNameEscrow__c);
                statementOfAccount.IBAN = ((salesOrderRec.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(salesOrderRec.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c)) ? salesOrderRec.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c : (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.IBANNoEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.IBANNoEscrow__c : salesOrderRec.Unit__r.Project__r.IBANNoEscrow__c));
                statementOfAccount.bankName = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BankNameEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BankNameEscrow__c : salesOrderRec.Unit__r.Project__r.BankNameEscrow__c);
                statementOfAccount.bankBranch = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BranchEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BranchEscrow__c : salesOrderRec.Unit__r.Project__r.BranchEscrow__c);
                statementOfAccount.bankAccountNumber = ((salesOrderRec.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(salesOrderRec.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c)) ? salesOrderRec.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c : salesOrderRec.Unit__r.Project__r.AccountNumberEscrow__c));
                statementOfAccount.swiftCode = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c : salesOrderRec.Unit__r.Project__r.SwiftCodeEscrow__c);
            }
            //-----If the Booking Date is on or after BCC date then Corporate of Building or Project to be used.
            else{
                statementOfAccount.beneficiaryName = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c : salesOrderRec.Unit__r.Project__r.BeneficiaryNameCorporate__c);
                statementOfAccount.bankAccountNumber = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c : salesOrderRec.Unit__r.Project__r.AccountNumberCorporate__c);
                statementOfAccount.bankName = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BankNameCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BankNameCorporate__c : salesOrderRec.Unit__r.Project__r.BankNameCorporate__c);
                statementOfAccount.bankBranch =(String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.BranchCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.BranchCorporate__c : salesOrderRec.Unit__r.Project__r.BranchCorporate__c);
                statementOfAccount.IBAN = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.IBANNoCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.IBANNoCorporate__c : salesOrderRec.Unit__r.Project__r.IBANNoCorporate__c);
                statementOfAccount.swiftCode = (String.isNotBlank(salesOrderRec.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c) ? salesOrderRec.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c : salesOrderRec.Unit__r.Project__r.SwiftCodeCorporate__c);
            }

            if(salesOrderRec.RecordType.Name==Constants.SO_RECORD_TYPE_RTO){
                statementOfAccount.agreementType = Constants.SO_RECORD_TYPE_RTO ;
            }
            else{
                statementOfAccount.agreementType = Constants.AGREEMENTTYPE_SALES_AGREEMENT ;
            }
            
            for(JointOwner__c joRecord : salesOrderRec.Joint_OwnersSalesOrder__r){
                statementOfAccount.jointOwnerNames = (String.isNotBlank(statementOfAccount.jointOwnerNames) ? statementOfAccount.jointOwnerNames: '') + '/' + joRecord.JointOwnerFullName__c ;
            }

            String fileName = 'SOA -'+salesOrderRec.Unit__r.Name+'-Generated On '+todayDate.format();

            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');

            

            //----- To show uncleared and cleared with outstanding reciepts in Other Charges table.
            for(ReceiptAcknowledgement__c receiptAcknowledgementRec : salesOrderRec.Payments__r){
                //----- Uncleared Receipts associated with Installment or Sales Order other charges
                if((receiptAcknowledgementRec.Status__c==Constants.RECEIVED_PAYMENT_STATUS || receiptAcknowledgementRec.Status__c==Constants.CONFIRMED_PAYMENT_STATUS || receiptAcknowledgementRec.Status__c==Constants.REMITTED_PAYMENT_STATUS ) && receiptAcknowledgementRec.PaymentSubType__c == null){
                    statementOfAccount.totalUnClearedReceipts = statementOfAccount.totalUnClearedReceipts + receiptAcknowledgementRec.Amount__c ;
                    statementOfAccount.recievedReceipts.add(receiptAcknowledgementRec);            
                }
                //---- Show cleared receipts and are unallocated
                if(receiptAcknowledgementRec.Status__c==Constants.RECEIPT_STATUS_CLEARED && receiptAcknowledgementRec.OutstandingAmount__c > 100 && receiptAcknowledgementRec.PaymentSubType__c == null){
                    statementOfAccount.clearedReceipts.add(receiptAcknowledgementRec);
                    clearedAmountOutstanding = clearedAmountOutstanding + receiptAcknowledgementRec.OutstandingAmount__c ;
                }
                //--- Show Rebate if not reveresed
                if(Constants.PAYMENT_STATUS_ALLOWED_SOA.contains(receiptAcknowledgementRec.Status__c) && receiptAcknowledgementRec.PaymentSubType__c !=null && receiptAcknowledgementRec.PaymentSubType__c.contains(Constants.OFFER_TYPE_REBATE) && (salesOrderRec.LastInstallmentRebate__c !=null || salesOrderRec.OtherRebateAmount__c !=null) && !salesOrderRec.RebateForfeitureLetterSent__c){
                    receiptAcknowledgementRec.Amount__c = -receiptAcknowledgementRec.Amount__c;
                    statementOfAccount.rebateCreditNotes.add(receiptAcknowledgementRec);
                }
                //--- If receipt is credit note then show status as 'CM'
                if(receiptAcknowledgementRec.PaymentSubType__c !=null && receiptAcknowledgementRec.PaymentSubType__c.contains(Constants.OFFER_TYPE_REBATE)){
                    receiptAcknowledgementRec.Status__c = 'CM';
                }
                if(receiptAcknowledgementRec.Status__c == Constants.RECEIVED_PAYMENT_STATUS){
                    receiptAcknowledgementRec.Status__c = Constants.CONFIRMED_PAYMENT_STATUS ;          
                }
            }

            //----- Show Rebate when order is in Approve Pending and customer is eligible for Rebate
            if(statementOfAccount.rebateCreditNotes.size() < 1 && salesOrderRec.Status__c == Constants.STATUS_APPROVAL_PENDING && (salesOrderRec.LastInstallmentRebate__c !=null || salesOrderRec.OtherRebateAmount__c !=null) && !salesOrderRec.RebateForfeitureLetterSent__c){
                ReceiptAcknowledgement__c tempReceipt = new ReceiptAcknowledgement__c();
                Decimal rebateAmount = (salesOrderRec.LastInstallmentRebate__c !=null ? salesOrderRec.LastInstallmentRebate__c : salesOrderRec.OtherRebateAmount__c) ;
                tempReceipt.Amount__c = -rebateAmount;
                tempReceipt.PaymentSubType__c = 'Rebate Amount';
                tempReceipt.Status__c = 'CM';
                statementOfAccount.rebateCreditNotes.add(tempReceipt);
                clearedAmountOutstanding = clearedAmountOutstanding +  rebateAmount ;
            }

            System.debug(clearedAmountOutstanding+'**Receipts Cleared**'+statementOfAccount.totalUnClearedReceipts+'**Receipts Uncleared**'+statementOfAccount.recievedReceipts);

            //----- Verify receipts allocated to the installment which are cleared
            for(ReceiptAllocation__c receiptAllocationRec : salesOrderRec.ReceiptAllocations__r){
                List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();

                if(receiptAllocationRec.InstallmentLine__c !=null){
                    if(receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED){
                        List<ReceiptAllocation__c> clearedAllocationList = new List<ReceiptAllocation__c>();
                        clearedAllocationList.add(receiptAllocationRec);
                        if(installmentAllocationMap.containsKey(receiptAllocationRec.InstallmentLine__c)){
                            clearedAllocationList.addAll(installmentAllocationMap.get(receiptAllocationRec.InstallmentLine__c));
                        }               
                        installmentAllocationMap.put(receiptAllocationRec.InstallmentLine__c,clearedAllocationList);
                        System.debug(receiptAllocationRec.InstallmentLine__c+'**installmentAllocationMap**'+installmentAllocationMap);
                    }
                    if(receiptAllocationRec.ReceiptAcknowledgement__r.ReceiptNumber__c!=null && Constants.PAYMENT_STATUS_ALLOWED_SOA.contains(receiptAllocationRec.ReceiptAcknowledgement__r.Status__c)){
                        allocationList.add(receiptAllocationRec);
                        if(installmentAllAllocationMap.containsKey(receiptAllocationRec.InstallmentLine__c)){
                            allocationList.addAll(installmentAllAllocationMap.get(receiptAllocationRec.InstallmentLine__c));
                        }
                        installmentAllAllocationMap.put(receiptAllocationRec.InstallmentLine__c,allocationList);
                        System.debug(receiptAllocationRec.InstallmentLine__c+'**installmentAllAllocationMap**'+installmentAllocationMap);
                    }
                }
                else if(receiptAllocationRec.SalesOrderOtherCharges__c !=null){
                    allocationList.add(receiptAllocationRec);
                    System.debug(receiptAllocationRec.SalesOrderOtherCharges__c+'**otherChargeAllocationMap**'+otherChargeAllocationMap);
                    if(otherChargeAllocationMap.containsKey(receiptAllocationRec.SalesOrderOtherCharges__c)){
                        allocationList.addAll(otherChargeAllocationMap.get(receiptAllocationRec.SalesOrderOtherCharges__c));
                    }
                    otherChargeAllocationMap.put(receiptAllocationRec.SalesOrderOtherCharges__c,allocationList);
                }
                //--- If receipt is credit note then show status as 'CM'
                if(receiptAllocationRec.ReceiptAcknowledgement__r.PaymentSubType__c !=null && receiptAllocationRec.ReceiptAcknowledgement__r.PaymentSubType__c.contains(Constants.OFFER_TYPE_REBATE)){
                    receiptAllocationRec.ReceiptAcknowledgement__r.Status__c = 'CM';
                }
                if(receiptAllocationRec.ReceiptAcknowledgement__r.Status__c == Constants.RECEIVED_PAYMENT_STATUS){
                    receiptAllocationRec.ReceiptAcknowledgement__r.Status__c= Constants.CONFIRMED_PAYMENT_STATUS ;          
                }
                System.debug(installmentAllocationMap+'**Installment Receipt Map**'+otherChargeAllocationMap);
            }

            

            /*
            * Build Installment Details Table 
            */
            Integer installmentCount = salesOrderRec.InstallmentLines__r.size() ;
            for(InstallmentLines__c installmentRec : salesOrderRec.InstallmentLines__r){

                if(String.isNotBlank(installmentRec.InvoiceNumber__c)){
                    statementOfAccount.totalInstallmentAmountDue = statementOfAccount.totalInstallmentAmountDue + installmentRec.OutstandingAmount__c ;
                    statementOfAccount.totalAmountDue = statementOfAccount.totalAmountDue + installmentRec.OutstandingAmount__c ; 
                }
                    

                List<ReceiptAllocation__c> receiptAllocationList = (installmentAllocationMap.containsKey(installmentRec.Id) ? installmentAllocationMap.get(installmentRec.Id) :  new List<ReceiptAllocation__c>());
                List<ReceiptAllocation__c> receiptAllocationAllList = (installmentAllAllocationMap.containsKey(installmentRec.Id) ? installmentAllAllocationMap.get(installmentRec.Id) :  new List<ReceiptAllocation__c>());
               
                System.debug('**Inst #**'+installmentRec.InstallmentNumber__c+'****'+receiptAllocationList.size()+'**Receipt Allocation List**'+receiptAllocationList);
                Boolean isLastInstallment = (installmentCount == installmentRec.InstallmentNumber__c ? true : false) ;
                /*
                * Installment Date is on or before Booked Date (Removed because Mamsha-T9-05-07)
                * Invoice Number is not available
                * LPC is waived
                * HandoverReadyforOccupancyDate__c is not available on Sales Order
                * Installment Payout date (Installment Date + Grace Days) is in the past
                */
                if(installmentRec.InstallmentNumber__c == 1 || (!isLastInstallment && installmentRec.InvoiceNumber__c==null) || (isLastInstallment && salesOrderRec.HandoverReadyforOccupancyDate__c ==null) || installmentRec.LPCWaived__c || installmentRec.InstallmentPayoutDate__c > todayDate || installmentRec.LPCExcluded__c){
                    //----- Change Installment Date to extension date and if available else if its last installment & has RFO date else installment date
                    installmentRec.InstallmentDate__c  = (installmentRec.ExtensionDate__c!=null ? installmentRec.ExtensionDate__c : (isLastInstallment && salesOrderRec.HandoverReadyforOccupancyDate__c !=null ? salesOrderRec.HandoverReadyforOccupancyDate__c : installmentRec.InstallmentDate__c));
                    statementOfAccount.installmentDetails.add(new StatementOfAccountModel_STAGING.InstallmentDetail(installmentRec,0,receiptAllocationList));
                }
                //--- Installments which are invoiced and has outstanding balance need to be checked against the LPC
                else{
                        Decimal lpcAmount = 0;
                        lpcAmount = LPCService_STAGING.getLPCAmount(installmentRec,receiptAllocationList,salesOrderRec,isLastInstallment);
                        //---- Paid or waived amount to be prorated
                        if(totalLPCWaivedOrPaid != 0){
                            System.debug(totalLPCWaivedOrPaid+'**totalLPCWaivedOrPaid Before**'+lpcAmount);
                            if(totalLPCWaivedOrPaid > lpcAmount){
                                totalLPCWaivedOrPaid = totalLPCWaivedOrPaid - lpcAmount ;
                                lpcAmount = 0 ;
                            }
                            else{
                                lpcAmount =  lpcAmount - totalLPCWaivedOrPaid ;
                                totalLPCWaivedOrPaid = 0 ;
                            } 
                            System.debug(totalLPCWaivedOrPaid+'**totalLPCWaivedOrPaid After**'+lpcAmount);
                        }
                        statementOfAccount.totalLPC = (statementOfAccount.totalLPC !=null ? statementOfAccount.totalLPC : 0) + lpcAmount ;
                        System.debug(lpcAmount+'**Inst #**'+installmentRec.InstallmentNumber__c+'****'+receiptAllocationList.size()+'**Receipt Allocation List**'+receiptAllocationList);
                        statementOfAccount.installmentDetails.add(new StatementOfAccountModel_STAGING.InstallmentDetail(installmentRec,lpcAmount,receiptAllocationAllList));
                    }
                System.debug(receiptAllocationList.size()+'**statementOfAccount.installmentDetails**'+statementOfAccount.installmentDetails);
            }
            /*
            * Build Other Charges Details Table 
            */
            statementOfAccount.otherCharges = new List<StatementOfAccountModel_STAGING.OtherChargeDetails>();
            for(SalesOrderOtherCharges__c otherChargeRec : salesOrderRec.SalesOrdersOtherCharges__r){
                List<ReceiptAllocation__c> receiptAllocationList = (otherChargeAllocationMap.containsKey(otherChargeRec.Id) ? otherChargeAllocationMap.get(otherChargeRec.Id) :  new List<ReceiptAllocation__c>());
                if(otherChargeRec.TypeOfCharge__c ==Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT || otherChargeRec.InvoiceNumber__c !=null){
                    statementOfAccount.totalOtherCharge = statementOfAccount.totalOtherCharge + otherChargeRec.Amount__c ;
                    statementOfAccount.otherCharges.add(new StatementOfAccountModel_STAGING.OtherChargeDetails(otherChargeRec,receiptAllocationList));
                    System.debug(receiptAllocationList.size()+'**statementOfAccount.otherCharges**'+statementOfAccount.otherCharges);
                    if(String.isNotBlank(otherChargeRec.InvoiceNumber__c)){
                        statementOfAccount.totalAmountDue = statementOfAccount.totalAmountDue + otherChargeRec.OutstandingAmount__c ; 
                    }
                }   
            }

            if(statementOfAccount.totalLPC !=null ){
                statementOfAccount.totalLPC = statementOfAccount.totalLPC.setScale(2);
                statementOfAccount.totalAmountDue = statementOfAccount.totalAmountDue + statementOfAccount.totalLPC ;
                statementOfAccount.totalOtherCharge = statementOfAccount.totalOtherCharge + statementOfAccount.totalLPC ;
                if(clearedAmountOutstanding!=null && clearedAmountOutstanding > 0){
                    statementOfAccount.totalAmountDue = statementOfAccount.totalAmountDue - clearedAmountOutstanding ;
                }
            }

            if(statementOfAccount.totalAmountDue !=null && statementOfAccount.totalAmountDue>0){
                statementOfAccount.amountInWordsDue = Utilities.amountInWords(statementOfAccount.totalAmountDue , 'dirhams','fils');
            }

        }catch (Exception e) {
            throw e;
        }
    }

    public static SalesOrder__c getSalesOrderDetail(Id salesOrderId){

        //------ Query Sales Order and related records
        SalesOrder__c salesOrderRec = [SELECT Id,Name,Opportunity__c,Unit__r.Name,Account__r.Name,Account__r.AccountNumber__c,ADMPercentage__c,AccountPhone__c,AccountMobileNumber__c,AccountEmail__c,BookingDate__c,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingCountry,Unit__r.ADMPlotNumber__c,Unit__r.ADMSectorName__c,Unit__r.ADMARBSectorName__c,Unit__r.ADMBuildingNumber__c,Unit__r.ProjectName__c,Unit__r.ADMZone__c,Unit__r.UnitModel__c,NetAmount__c,MortgageApplicable__c,MortgageBank__c,Unit__r.UnitType__c,RecordType.Name,SoldDate__c,Unit__r.ADMUnitNumber__c,TotalBilled__c,TotalOutstanding__c,Unit__r.BuildingSectionName__r.Name, Unit__r.BuildingSectionName__r.LatePaymentCharges__c,HandoverRFOPayDueDate__c,HandoverReadyforOccupancyDate__c,BeneficiaryName__c,RebateForfeitureLetterSent__c,BankAccountNumber__c,BankName__c,BankBranch__c,IBANNo__c,SwiftCode__c,LastInstallmentRebate__c,OtherRebateAmount__c,Unit__r.BuildingSectionName__r.CompletionCertificateDate__c,Unit__r.Project__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,Unit__r.Project__r.AccountNumberEscrow__c,Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c,Unit__r.BuildingSectionName__r.BranchEscrow__c,Unit__r.Project__r.BranchEscrow__c,Unit__r.BuildingSectionName__r.BranchCorporate__c,Unit__r.Project__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.BankNameEscrow__c,Unit__r.Project__r.BankNameEscrow__c,Unit__r.BuildingSectionName__r.BankNameCorporate__c,Unit__r.Project__r.BankNameCorporate__c,Unit__r.Project__r.IBANNoEscrow__c,Unit__r.BuildingSectionName__r.IBANNoEscrow__c,Unit__r.Project__r.IBANNoCorporate__c,Unit__r.BuildingSectionName__r.IBANNoCorporate__c,Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c,Unit__r.Project__r.SwiftCodeEscrow__c,Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,Unit__r.Project__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,Unit__r.Project__r.BeneficiaryNameCorporate__c,Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c,Unit__r.Project__r.BeneficiaryNameEscrow__c,Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,Status__c,
        (SELECT Id, InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,Description__c,InstallmentPercentage__c,InvoiceNumber__c,InvoicedAmount__c,OutstandingAmount__c,RevisedDate__c,LPCPercentage__c,LPCWaived__c,LPCGraceDays__c,InstallmentPayoutDate__c,ExtensionDate__c,LPCExcluded__c,LPCFreezeDate__c,LPCFreezeUntilDate__c
        FROM InstallmentLines__r ORDER BY InstallmentNumber__c ASC),(SELECT Id,Name,Amount__c,TypeOfCharge__c,InvoicedAmount__c,InvoiceNumber__c,OutstandingAmount__c FROM SalesOrdersOtherCharges__r),(SELECT Id,Name, InstallmentLine__c,ReceiptAcknowledgement__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.ReferenceNumber__c,ReceiptAcknowledgement__r.ReceiptNumber__c,AmountApplied__c,InstallmentNumberOrChargeType__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.BankName__c,InstallmentLine__r.InstallmentPercentage__c,InstallmentLine__r.InvoiceNumber__c,ReceiptAcknowledgement__r.ClearedDate__c,ReceiptAcknowledgement__r.PaymentType__c,ReceiptAcknowledgement__r.PaymentSubType__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.ChequeReceived__c ,ReceiptAcknowledgement__r.SoADate__c FROM ReceiptAllocations__r WHERE Unapply__c=false AND AmountApplied__c > 1 AND ReceiptAcknowledgement__r.PaymentType__c !=:RECEIPT_ADJUSTMENT ORDER BY ReceiptAcknowledgement__r.ClearedDate__c DESC,InstallmentNumberOrChargeType__c),(Select Id,Name,JointOwnerFullName__c FROM Joint_OwnersSalesOrder__r),(Select Id,ReceiptNumber__c,ReceiptDate__c,OutstandingAmount__c,Amount__c,Status__c,MaturityDate__c,ReferenceNumber__c,SoADate__c,PaymentSubType__c FROM Payments__r WHERE Amount__c>0 AND ReceiptNumber__c!=null AND PaymentType__c !=:RECEIPT_ADJUSTMENT ORDER BY SoADate__c) FROM SalesOrder__c WHERE Id=:salesOrderId];

        return salesOrderRec ;

    }

    public static List<SalesOrder__c> getListSalesOrderDetail(List<Id> salesOrdersIdsSet){

        //------ Query Sales Order and related records
        List<SalesOrder__c> salesOrderList = [SELECT Id,Name,Opportunity__c,Unit__r.Name,Account__r.Name,Account__r.AccountNumber__c,ADMPercentage__c,AccountPhone__c,AccountMobileNumber__c,AccountEmail__c,BookingDate__c,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingCountry,Unit__r.ADMPlotNumber__c,Unit__r.ADMSectorName__c,Unit__r.ADMARBSectorName__c,Unit__r.ADMBuildingNumber__c,Unit__r.ProjectName__c,Unit__r.ADMZone__c,Unit__r.UnitModel__c,NetAmount__c,MortgageApplicable__c,MortgageBank__c,Unit__r.UnitType__c,RecordType.Name,SoldDate__c,Unit__r.ADMUnitNumber__c,TotalBilled__c,TotalOutstanding__c,Unit__r.BuildingSectionName__r.Name, Unit__r.BuildingSectionName__r.LatePaymentCharges__c,HandoverRFOPayDueDate__c,HandoverReadyforOccupancyDate__c,BeneficiaryName__c,BankAccountNumber__c,BankName__c,BankBranch__c,IBANNo__c,SwiftCode__c,LastInstallmentRebate__c,OtherRebateAmount__c,Unit__r.BuildingSectionName__r.CompletionCertificateDate__c,Unit__r.Project__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,Unit__r.Project__r.AccountNumberEscrow__c,Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c,Unit__r.BuildingSectionName__r.BranchEscrow__c,Unit__r.Project__r.BranchEscrow__c,Unit__r.BuildingSectionName__r.BranchCorporate__c,Unit__r.Project__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.BankNameEscrow__c,Unit__r.Project__r.BankNameEscrow__c,Unit__r.BuildingSectionName__r.BankNameCorporate__c,Unit__r.Project__r.BankNameCorporate__c,Unit__r.Project__r.IBANNoEscrow__c,Unit__r.BuildingSectionName__r.IBANNoEscrow__c,Unit__r.Project__r.IBANNoCorporate__c,Unit__r.BuildingSectionName__r.IBANNoCorporate__c,Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c,Unit__r.Project__r.SwiftCodeEscrow__c,Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,Unit__r.Project__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,Unit__r.Project__r.BeneficiaryNameCorporate__c,Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c,Unit__r.Project__r.BeneficiaryNameEscrow__c,Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,Status__c,
        (SELECT Id, InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,Description__c,InstallmentPercentage__c,InvoiceNumber__c,InvoicedAmount__c,OutstandingAmount__c,RevisedDate__c,LPCPercentage__c,LPCWaived__c,LPCGraceDays__c,InstallmentPayoutDate__c,ExtensionDate__c,LPCExcluded__c,LPCFreezeDate__c,LPCFreezeUntilDate__c
        FROM InstallmentLines__r ORDER BY InstallmentNumber__c ASC),(SELECT Id,Name,Amount__c,TypeOfCharge__c,InvoicedAmount__c,InvoiceNumber__c,OutstandingAmount__c FROM SalesOrdersOtherCharges__r),(SELECT Id,Name, InstallmentLine__c,ReceiptAcknowledgement__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.ReferenceNumber__c,ReceiptAcknowledgement__r.ReceiptNumber__c,AmountApplied__c,InstallmentNumberOrChargeType__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.BankName__c,InstallmentLine__r.InstallmentPercentage__c,InstallmentLine__r.InvoiceNumber__c,ReceiptAcknowledgement__r.ClearedDate__c,ReceiptAcknowledgement__r.PaymentType__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.ChequeReceived__c ,ReceiptAcknowledgement__r.SoADate__c FROM ReceiptAllocations__r WHERE Unapply__c=false AND AmountApplied__c > 1 ORDER BY ReceiptAcknowledgement__r.ClearedDate__c DESC,InstallmentNumberOrChargeType__c),(Select Id,Name,JointOwnerFullName__c FROM Joint_OwnersSalesOrder__r),(Select Id,ReceiptNumber__c,ReceiptDate__c,OutstandingAmount__c,Amount__c,Status__c,MaturityDate__c,ReferenceNumber__c,SoADate__c FROM Payments__r WHERE Amount__c>0 AND ReceiptNumber__c!=null) FROM SalesOrder__c WHERE Id IN : salesOrdersIdsSet];

        return salesOrderList;

    }

    
}