public with sharing class ReceiptAllocationController {

    public class ReceiptModel {
        public String receiptId;
        public String accountName;
        public Id account;
        public String unitNumber;
        public String soNumber;
        public String paymentMode;
        public String chequeNo;
        public String currencyISOCode;
        public String mortageCheque;
        public Date maturityDate;
        public Decimal amount;
        public String bankName;
        public String bankAccountNo;
        public String paidBy;
        public String remarks;
        public List<InvoiceModel> rceiptAllocationList;
        public List<RelationshipModel> relatedAccounts;

        public ReceiptModel(ReceiptAcknowledgement__c receipt, List<InvoiceModel> rceiptAllocationList, List<RelationshipModel> relatedAccounts) {
            this.receiptId = receipt.Id;
            this.accountName = receipt.Account__r.Name;
            this.account = receipt.Account__c;
            this.unitNumber = receipt.SalesOrder__r.Unit__r.Name;
            this.soNumber = receipt.SalesOrder__r.Name;
            this.paymentMode = receipt.PaymentType__c;
            this.chequeNo = receipt.ReferenceNumber__c;
            this.currencyISOCode = receipt.CurrencyISOCode;
            this.mortageCheque = receipt.MortgageCheque__c ? 'Yes' : 'No';
            this.maturityDate = receipt.MaturityDate__c;
            this.amount = receipt.Amount__c;
            this.bankName = receipt.BankName__c;
            this.bankAccountNo = receipt.CustomerBankAccount__c;
            this.paidBy = receipt.PaidBy__c;
            this.remarks = receipt.Remarks__c;
            this.rceiptAllocationList = rceiptAllocationList;
            this.relatedAccounts = relatedAccounts;
        }
    }

    public class RelationshipModel {
        public String label;
        public String value;
        public String accountId;

        public RelationshipModel (String label, String value) {
            this.label = label;
            this.value = label;
            this.accountId = value;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static String getReceiptAllocationbyReceiptId(Id receiptId){
        ReceiptModel returnReceiptModel;
        List<ReceiptAcknowledgement__c> receiptList = ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(new List<Id>{receiptId});
        
        if (!receiptList.isEmpty()) {
            List<InvoiceModel> invoiceModelList = prepareReceiptAllocation(receiptList[0].Receipt_Allocations__r);
            List<RelationshipModel> relatedAccounts = new List<RelationshipModel>();
            relatedAccounts.addAll(getRelatedAccountbyAccountId(receiptList[0].Account__c));
//            List<TransferHistory__c> transFerHistoryList = new List<TransferHistory__c>();
            if(receiptList[0].SalesOrder__c != null){
                Boolean isPresent = false;
                for(RelationshipModel acc : relatedAccounts){
                    if(acc.accountId == receiptList[0].SalesOrder__r.Account__c){
                        isPresent = true;
                        break;
                    }
                }
                if(!isPresent){
                    relatedAccounts.add(new RelationshipModel(receiptList[0].SalesOrder__r.Account__r.Name, receiptList[0].SalesOrder__r.Account__c));
                }
              /*   transFerHistoryList = [SELECT Id,FromAccount__c,FromAccount__r.Name,ToAccount__r.Name,ToAccount__c
                                       FROM TransferHistory__c
                                       WHERE SalesOrder__c =:receiptList[0].SalesOrder__c 
                                       ORDER BY TransferDate__c DESC LIMIT 1 ];
               if(transFerHistoryList.size() > 0){
                    boolean isFromAccountPresent = false;
                    boolean isToAccountPresent = false;
                        
                        
                        for(RelationshipModel acc : relatedAccounts){
                            if(acc.accountId == transFerHistoryList[0].FromAccount__c){
                                isFromAccountPresent = true;
                            }
                            if(acc.accountId == transFerHistoryList[0].ToAccount__c){
                                isToAccountPresent = true;
                            }
                        }
                    if(!isFromAccountPresent && transFerHistoryList[0].FromAccount__c == receiptList[0].SalesOrder__r.Account__c ){
                        relatedAccounts.add(new RelationshipModel(transFerHistoryList[0].FromAccount__r.Name, transFerHistoryList[0].FromAccount__c));
                    }
                    if(!isToAccountPresent && transFerHistoryList[0].ToAccount__c == receiptList[0].SalesOrder__r.Account__c){
                        relatedAccounts.add(new RelationshipModel(transFerHistoryList[0].ToAccount__r.Name, transFerHistoryList[0].ToAccount__c));
                    }
                    
                }	*/
            }else{
                relatedAccounts.add(new RelationshipModel(receiptList[0].Account__r.Name, receiptList[0].Account__c));
            }
            returnReceiptModel = new ReceiptModel(receiptList[0], invoiceModelList, relatedAccounts);
        }

        System.debug('returnReceiptModel>>>' + JSON.serialize(returnReceiptModel));
        return JSON.serialize(returnReceiptModel);
    }

    public static List<InvoiceModel> prepareReceiptAllocation(List<ReceiptAllocation__c> receiptAllocationList) {
        List<InvoiceModel> invoiceModelList = new List<InvoiceModel>();
        for (ReceiptAllocation__c receiptAllocation: receiptAllocationList) {
            if(receiptAllocation.InstallmentLine__c != null || receiptAllocation.SalesOrderOtherCharges__c != null  ){
                Boolean isInstallment = receiptAllocation.InstallmentLine__c != null ? true : false;
                
                String no = isInstallment ? String.valueOf(receiptAllocation.InstallmentLine__r.InstallmentNumber__c) : receiptAllocation.SalesOrderOtherCharges__r.TypeOfCharge__c;
                Id installmentOtherChargeId = isInstallment ? receiptAllocation.InstallmentLine__c : receiptAllocation.SalesOrderOtherCharges__c;
                Decimal totalInvoiceAmount = isInstallment ? receiptAllocation.InstallmentLine__r.InstallmentAmount__c : receiptAllocation.SalesOrderOtherCharges__r.Amount__c;
                String type = isInstallment ? 'Installment' : receiptAllocation.SalesOrderOtherCharges__r.TypeOfCharge__c;
                
                invoiceModelList.add(new InvoiceModel(no, type, totalInvoiceAmount, (totalInvoiceAmount - receiptAllocation.AmountApplied__c), receiptAllocation.SalesOrder__c, installmentOtherChargeId, receiptAllocation.Account__r.Name, receiptAllocation.SalesOrder__r.Name, receiptAllocation.SalesOrder__r.Unit__r.Name, receiptAllocation.AmountApplied__c, receiptAllocation.Id));
                
            }
        }

        return invoiceModelList;
    }

    public static List<RelationshipModel> getRelatedAccountbyAccountId(Id accountId){
        List<RelationshipModel> relatedAccounts = new List<RelationshipModel>();
        List<AccountRelationship__c> allRelationships = AccountService.getRelatedAccountsForAccountId(accountId);
        for (AccountRelationship__c relationship: allRelationships) {
            relatedAccounts.add(new RelationshipModel(relationship.RelatedAccount__r.Name, relationship.RelatedAccount__c));
        }

        System.debug('relatedAccounts>>>' + JSON.serialize(relatedAccounts));
        return relatedAccounts;
    }

    public class SalesOrderModel {
        public String label;
        public String value;
        public String salesOrderId;
        public String salesOrderName;

        public SalesOrderModel (String label, String value, String salesOrderName) {
            this.label = label;
            this.value = label;
            this.salesOrderId = value;
            this.salesOrderName = salesOrderName;
        }
    }

    @AuraEnabled
    public static String getRelatedSalesOrderbyAccountId(Id accountId){
        List<SalesOrderModel> relatedSalesOrder = new List<SalesOrderModel>();
        List<SalesOrder__c> allSalesOrders = SalesOrderService.getSalesOrderByAccountId(new Set<Id>{accountId});
        for (SalesOrder__c salesOrder: allSalesOrders) {
            if ((salesOrder.Status__c != Constants.SO_STATUS_CANCELLED && salesOrder.Status__c != Constants.SO_STATUS_CANCELLED_BY_USER) || !salesOrder.SalesOrdersOtherCharges__r.isEmpty()) {
                relatedSalesOrder.add(new SalesOrderModel(salesOrder.Unit__r.Name + (salesOrder.RecordType.Name == Constants.SO_RECORD_TYPE_RTO ? '-' +Constants.SO_RECORD_TYPE_RTO:'' ) , salesOrder.Id, salesOrder.Name));
            }
        }

        System.debug('relatedSalesOrder>>>' + JSON.serialize(relatedSalesOrder));
        return JSON.serialize(relatedSalesOrder);
    }
    
    public class InvoiceModel{
        public String installmentNoOtherCharge;
        public String chargeType;
        public Decimal totalInvoiceAmount;
        public Decimal currentOutstandingAmount;
        public Decimal currentAmountApplied;
        public Decimal amountApplied;
        public Decimal finalOutstandingAmount;
        public Id salesOrderId;
        public Id installmentOtherChargeId;
        public String account;
        public String salesOrder;
        public String unitNumber;
        public Id Id;
        
        public InvoiceModel(String no, String chargeType, Decimal totalInvoiceAmount, Decimal currentOutstandingAmount, Id salesOrderId, Id installmentOtherChargeId, String accountName, String soNumber, String unitNumber, Decimal amountApplied, Id recordId){
            this.installmentNoOtherCharge = no;
            this.chargeType = chargeType;
            this.totalInvoiceAmount = totalInvoiceAmount.setscale(2);
            this.currentOutstandingAmount = currentOutstandingAmount.setscale(2);
            this.salesOrderId = salesOrderId;
            this.installmentOtherChargeId = installmentOtherChargeId;
            this.currentAmountApplied = amountApplied.setscale(2);
            this.amountApplied = amountApplied.setscale(2);
            this.finalOutstandingAmount = currentOutstandingAmount.setscale(2);
            this.account = accountName;
            this.salesOrder = soNumber;
            this.unitNumber = unitNumber;
            this.Id = recordId;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static String getInvoicesApplicableForSO(Id SalesOrderId){
        List<InvoiceModel> invoiceModelList = new List<InvoiceModel>();
        
        List<SalesOrder__c> salesOrderDetails = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{SalesOrderId});
        
        if(salesOrderDetails!=null && salesOrderDetails.size()>0){
            
            if (salesOrderDetails[0].Status__c != Constants.SO_STATUS_CANCELLED && salesOrderDetails[0].Status__c != Constants.SO_STATUS_CANCELLED_BY_USER) {
                for(InstallmentLines__c installmentLine: salesOrderDetails[0].InstallmentLines__r){
                    if (installmentLine.PendingAmount__c > 0) {
                        invoiceModelList.add(new InvoiceModel(String.valueOf(installmentLine.InstallmentNumber__c), 'Installment', installmentLine.InstallmentAmount__c, installmentLine.PendingAmount__c, installmentLine.SalesOrder__c, installmentLine.Id, '', '', '', 0, null));
                    }
                }
            }
            
            for(SalesOrderOtherCharges__c otherCharge: salesOrderDetails[0].SalesOrdersOtherCharges__r){
                if (otherCharge.PendingAmount__c > 0 && salesOrderDetails[0].Status__c != Constants.SO_STATUS_CANCELLED && salesOrderDetails[0].Status__c != Constants.SO_STATUS_CANCELLED_BY_USER) {
                    invoiceModelList.add(new InvoiceModel(otherCharge.TypeOfCharge__c + ' - ' + otherCharge.Name, otherCharge.TypeOfCharge__c, otherCharge.Amount__c, otherCharge.PendingAmount__c, otherCharge.SalesOrder__c, otherCharge.Id, '', '', '', 0, null));
                } else if (otherCharge.TypeOfCharge__c == constants.OTHER_CHARGES_TYPE_DEBIT_MEMO && otherCharge.PendingAmount__c > 0) {
                    invoiceModelList.add(new InvoiceModel(otherCharge.TypeOfCharge__c + ' - ' + otherCharge.SubType__c, otherCharge.TypeOfCharge__c + ' - ' + otherCharge.SubType__c, otherCharge.Amount__c, otherCharge.PendingAmount__c, otherCharge.SalesOrder__c, otherCharge.Id, '', '', '', 0, null));
                }
            }
        }
        System.debug('invoiceModelList>>>' + JSON.serialize(invoiceModelList));
        return JSON.serialize(invoiceModelList);
    }

    public class ReceiptAllocationModel {
        public String Id;
        public String account;
        public String accountId;
        public String salesOrder;
        public String salesOrderId;
        public String unitNumber;
        public String installmentNoOtherCharge;
        public String installmentOtherChargeId;
        public Boolean isInstallment;
        public String chargeType;
        public Decimal totalInvoiceAmount;
        public Decimal currentOutstandingAmount;
        public Decimal currentAmountApplied;
        public Decimal amountApplied;
        public Decimal finalOutstandingAmount;
    }

    @AuraEnabled
    public static string saveReceiptAllocation(String receiptAllocations, String receiptId){
        try {
            List<ReceiptAllocationModel> receiptAllocationList = (List<ReceiptAllocationModel>)System.JSON.deserialize(receiptAllocations, List<ReceiptAllocationModel>.class);
            system.debug('receiptAllocationList ---> '+JSON.serializePretty(receiptAllocationList));
            List<ReceiptAllocation__c> upsertReceiptAllocationList = new List<ReceiptAllocation__c>();
            for (ReceiptAllocationModel receiptAllocation: receiptAllocationList) {
                ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
                if (receiptAllocation.Id != '') {
                    newReceiptAllocation.Id = receiptAllocation.Id;
                    newReceiptAllocation.AmountApplied__c = receiptAllocation.amountApplied;
                } else {
                    if (receiptAllocation.isInstallment) {
                        newReceiptAllocation.InstallmentLine__c = receiptAllocation.installmentOtherChargeId;
                    } else {
                        newReceiptAllocation.SalesOrderOtherCharges__c = receiptAllocation.installmentOtherChargeId;
                    }
                    newReceiptAllocation.TypeOfInvoice__c = receiptAllocation.isInstallment ? Constants.INVOICE_TYPE_INSTALLMENT : receiptAllocation.chargeType.containsIgnoreCase(Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO) ? Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO : receiptAllocation.chargeType;
                    newReceiptAllocation.ReceiptAcknowledgement__c = receiptId;
                    newReceiptAllocation.AmountApplied__c = receiptAllocation.amountApplied;
                    // newReceiptAllocation.CurrencyIsoCode = receiptAllocation.CurrencyIsoCode;
                    newReceiptAllocation.DateOfApplication__c = Date.today();
                    newReceiptAllocation.Account__c = receiptAllocation.accountId;
                    newReceiptAllocation.SalesOrder__c = receiptAllocation.salesOrderId;
                }
                upsertReceiptAllocationList.add(newReceiptAllocation);
            }

            if (!upsertReceiptAllocationList.isEmpty()) {
                // System.debug('upsertReceiptAllocationList>>>' + upsertReceiptAllocationList);
                upsert upsertReceiptAllocationList;
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return 'success';
    }

    /**
     * @description FIN-68: Controls receipt allocation modification permissions based on receipt status and user group membership.
     *              - All users can modify if receipt status is not 'Cleared'
     *              - Only users in 'Receipt Cleared Group' can modify if status is 'Cleared'
     * @author Sai Kumar
     * @param receiptId The ID of the receipt to check permissions for
     * @return Boolean indicating if user can modify the receipt
     */
    @AuraEnabled(cacheable=false)
    public static Boolean canUserModifyReceipt(Id receiptId) {
        try {
            ReceiptAcknowledgement__c receipt = [SELECT Id, Status__c 
                                               FROM ReceiptAcknowledgement__c 
                                               WHERE Id = :receiptId 
                                               LIMIT 1];
            
            if (receipt.Status__c != 'Cleared') {
                return true;
            }
            
            Id currentUserId = UserInfo.getUserId();
            List<GroupMember> groupMembers = [
                SELECT Id 
                FROM GroupMember 
                WHERE Group.Name = 'Receipt Cleared Group' 
                AND UserOrGroupId = :currentUserId
            ];
            
            return !groupMembers.isEmpty();
            
        } catch (Exception e) {
            // Default to true to maintain existing functionality if permission check fails
            return true;
        }
    }
}