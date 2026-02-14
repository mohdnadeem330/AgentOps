/**********************************************************************************************************************
* Name               : CustomerPaymentReceiptWebService                                                        
* Description        : Class to Create ReceiptAcknowledgement & ReceiptAllocation
* Usage              : Lean Payment Gateway in Live Aldar App
* Created By         : Live Aldar Salesforce Team                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           tdevar@aldar.com     11/09/2025      Initial Draft       
**********************************************************************************************************************/

@RestResource(urlMapping = '/customer/paymentReceipt')
global class CustomerPaymentReceiptWebService {
    
    @HttpPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint sp;
        try {
            sp = Database.setSavepoint();
            String requestBody = RestContext.request.requestBody.toString();
            handler.response.data = createPaymentReceipts(requestBody);
            handler.response.message = Constants.SUCCESS_MESSAGE;
            handler.response.statusCode = Constants.SUCCESS_CODE_200;
            handler.response.success = true;
            handler.finalize();
            
        } catch (Exception ex) {
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    global static Map<String,Object> createPaymentReceipts(String requestBody) {
        
        Map<String,Object> requestMap = (Map<String,Object>) JSON.deserializeUntyped(requestBody);
        
        if(!requestMap.containsKey('ReceiptAcknowledgement__c') || !requestMap.containsKey('ReceiptAllocation__c') || !requestMap.containsKey('Source')) {
            throw new customException ('Missing or invalid input parameters : ReceiptAcknowledgement__c, ReceiptAllocation__c, Source are required fields');
        }
        
        String source = (String) requestMap.get('Source');
        Map<String,Object> receiptMap = (Map<String,Object>) requestMap.get('ReceiptAcknowledgement__c');
        
        Object res = receiptMap.get('JSONResponse__c');
        if(res != null) {
            receiptMap.put('JSONResponse__c',JSON.serialize(res));
        }
        
        String receiptBody = JSON.serialize(receiptMap);
        ReceiptAcknowledgement__c receipt = (ReceiptAcknowledgement__c) JSON.deserialize(receiptBody, ReceiptAcknowledgement__c.class);
        
        List<SalesOrder__c> salesOrderList = [SELECT Id,Account__c,Account__r.PersonContactId,Opportunity__c,Is_Digital_Sales__c,SalesManager__c,SalesManager__r.Email,Account__r.PersonEmail FROM SalesOrder__c WHERE Id =: receipt.SalesOrder__c LIMIT 1];
        if(salesOrderList.isEmpty()) throw new customException('Sales Order not found with provided ID.');
        
        String recAllocationBody = JSON.Serialize(requestMap.get('ReceiptAllocation__c'));
        List<ReceiptAllocation__c> recAllocationList = (List<ReceiptAllocation__c>) JSON.Deserialize(recAllocationBody, List<ReceiptAllocation__c>.class);
        
        if(recAllocationList == null || recAllocationList.isEmpty()) throw new customException('ReceiptAllocation__c list is empty, Provide at least one allocation.');
        
        Map<String,Object> resultResponse = createReceiptAcknowledgement(receipt,recAllocationList[0],salesOrderList[0],source);
        
        return resultResponse;
    }
    
    public static Map<String,Object> createReceiptAcknowledgement(ReceiptAcknowledgement__c receipt,ReceiptAllocation__c recAll,SalesOrder__c salesOrder,String source) {    
        
        Decimal amountPending = 0;
        
        if(receipt.Amount__c == null || receipt.Amount__c <= 0) throw new customException ('Amount is required and must be greater than zero for creating payment receipts.');
        
        if(String.isBlank(recAll.InstallmentLine__c) && String.isBlank(recAll.SalesOrderOtherCharges__c)) throw new customException ('Either installmentId or salesOrderOtherChargeId must be provided.');
        
        if(!String.isBlank(recAll.InstallmentLine__c) && !String.isBlank(recAll.SalesOrderOtherCharges__c)) throw new customException ('Only one of installmentId or salesOrderOtherChargeId must be provided.');
        
        List<ReceiptAcknowledgement__c> existingReceipt = [SELECT Id FROM ReceiptAcknowledgement__c WHERE ReferenceNumber__c =: receipt.ReferenceNumber__c AND AuthenticationReferenceNumber__c =: receipt.AuthenticationReferenceNumber__c LIMIT 1];
        
        if(!existingReceipt.isEmpty()) {
            return createResult(existingReceipt[0],'Payment receipt already exists with reference number - ' + receipt.ReferenceNumber__c);
        } else {
            ReceiptAcknowledgement__c receiptAck = new ReceiptAcknowledgement__c(
                SalesOrder__c = receipt.SalesOrder__c,
                Opportunity__c = receipt.Opportunity__c,
                Account__c = receipt.Account__c,
                Contact__c = salesOrder.Account__r != null ? salesOrder.Account__r.PersonContactId : null,
                Status__c = Constants.RECEIVED_PAYMENT_STATUS,
                Amount__c = receipt.Amount__c,
                ReceiptDate__c = Date.today(),
                PaymentType__c = Constants.WIRE_TRANSFER,
                BankName__c = Constants.ABUDHABI_COMMERCIAL_BANK,
                ReferenceNumber__c = receipt.ReferenceNumber__c,
                AuthenticationReferenceNumber__c = receipt.AuthenticationReferenceNumber__c,
                MaturityDate__c = Date.today(),
                ChequeReceived__c = true,
                Payment_Gateway__c = source,
                PaidBy__c = receipt.PaidBy__c,
                CustomerBankAccount__c = receipt.CustomerBankAccount__c,
                Decision__c = receipt.Decision__c,
                JSONResponse__c = receipt.JSONResponse__c,
                SyncStatus__c = Constants.STATUS_IN_PROGRESS
            );
            if(salesOrder.Is_Digital_Sales__c) {
                receiptAck.Sales_Manager__c = salesOrder.SalesManager__c;
                receiptAck.Sales_Manager_Email__c = salesOrder.SalesManager__r.Email;
                receiptAck.ReceiptEmail__c = salesOrder.Account__r.PersonEmail;
            }
            
            if(!String.isBlank(recAll.InstallmentLine__c) || !String.isBlank(recAll.SalesOrderOtherCharges__c)) {
                amountPending = getInstalmentOtherChargesPendingAmt(recAll,salesOrder);
            }
            
            if(amountPending > 0) {
                ReceiptAcknowledgementController.isCreatingBothReceiptAndAllocation = true;
            }
            try {
                insert receiptAck;
                if(amountPending > 0) {
                    createReceiptAllocation(recAll,receiptAck,salesOrder);
                }
            } 
            catch(exception ex){
                throw new customException('Receipt creation failed >>>> : ' + ex.getMessage());
            }
            finally {
                ReceiptAcknowledgementController.isCreatingBothReceiptAndAllocation = false;
            }
            return createResult(receiptAck,'Payment Receipt Created Successfully!'); 
        }
    }
    
    public static ReceiptAllocation__c createReceiptAllocation(ReceiptAllocation__c recAllocation,ReceiptAcknowledgement__c receipt,SalesOrder__c salesOrder) {
        
        Decimal amountPending = 0;
        ReceiptAllocation__c recAll = new ReceiptAllocation__c( 
            ReceiptAcknowledgement__c = receipt.Id,
            SalesOrder__c = salesOrder.Id,
            DateOfApplication__c = System.today(),
            Account__c = salesOrder.Account__c,
            SyncStatus__c = Constants.STATUS_IN_PROGRESS
        );
        
        if(!String.isBlank(recAllocation.InstallmentLine__c)) {
            amountPending = getInstalmentOtherChargesPendingAmt(recAllocation,salesOrder);
            recAll.InstallmentLine__c = recAllocation.InstallmentLine__c;
            recAll.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT;
        }
        
        if(!String.isBlank(recAllocation.SalesOrderOtherCharges__c)) {
            amountPending = getInstalmentOtherChargesPendingAmt(recAllocation,salesOrder);
            recAll.SalesOrderOtherCharges__c = recAllocation.SalesOrderOtherCharges__c;
            if((getSalesOrderOtherCharges(recAllocation,salesOrder)).containsKey(recAllocation.SalesOrderOtherCharges__c)){
                recAll.TypeOfInvoice__c = (getSalesOrderOtherCharges(recAllocation,salesOrder).get(recAllocation.SalesOrderOtherCharges__c)).TypeOfCharge__c;
            }
        }
        
        if(amountPending > 0) {
            recAll.AmountApplied__c = (receipt.Amount__c > amountPending ? amountPending : receipt.Amount__c);
            
            insert recAll;
            if(recAll.Id == null) throw new customException('Receipt allocation creation failed.');
        }
        return recAll;
    }
    
    public static Decimal getInstalmentOtherChargesPendingAmt(ReceiptAllocation__c recAllocation,SalesOrder__c salesOrder) {
        Map<Id,InstallmentLines__c> getInstalmentLinesMap = new Map<Id,InstallmentLines__c>();
        Map<Id,SalesOrderOtherCharges__c> getSalesOrderOtherChargesMap = new Map<Id,SalesOrderOtherCharges__c>();
        Decimal amountPending = 0;
        if(!String.isBlank(recAllocation.InstallmentLine__c)) {
            getInstalmentLinesMap = getInstallmentLines(recAllocation,salesOrder);
            if(getInstalmentLinesMap.containsKey(recAllocation.InstallmentLine__c)) {
                amountPending = (getInstalmentLinesMap.get(recAllocation.InstallmentLine__c)).PendingAmount__c;
            }
        }
        
        if(!String.isBlank(recAllocation.SalesOrderOtherCharges__c)) {
            getSalesOrderOtherChargesMap = getSalesOrderOtherCharges(recAllocation,salesOrder);
            if(getSalesOrderOtherChargesMap.containsKey(recAllocation.SalesOrderOtherCharges__c)) {
                amountPending = (getSalesOrderOtherChargesMap.get(recAllocation.SalesOrderOtherCharges__c)).PendingAmount__c;  
            }
        }
        return amountPending;
    }
    
    public static Map<Id,InstallmentLines__c> getInstallmentLines(ReceiptAllocation__c recAllocation,SalesOrder__c salesOrder) {
        Map<Id,InstallmentLines__c> getInstalmentLinePendingAmt = new Map<Id,InstallmentLines__c>();
        List<InstallmentLines__c>  installmentList = [SELECT Id,PendingAmount__c FROM InstallmentLines__c WHERE Id =: recAllocation.InstallmentLine__c AND SalesOrder__c =: salesOrder.Id LIMIT 1];
        if(installmentList.isEmpty()) {
            throw new customException('Installment Id not found with provided ID or does not belong to the Sales Order.');
        }
        getInstalmentLinePendingAmt.put(installmentList[0].Id,installmentList[0]);
        return getInstalmentLinePendingAmt;
    }
    
    public static Map<Id,SalesOrderOtherCharges__c> getSalesOrderOtherCharges(ReceiptAllocation__c recAllocation,SalesOrder__c salesOrder) {
        Map<Id,SalesOrderOtherCharges__c> getOtherChargesPendingAmt = new Map<Id,SalesOrderOtherCharges__c>();
        List<SalesOrderOtherCharges__c> otherChargeList = [SELECT Id,TypeOfCharge__c,PendingAmount__c FROM SalesOrderOtherCharges__c WHERE Id =: recAllocation.SalesOrderOtherCharges__c AND SalesOrder__c =: salesOrder.Id LIMIT 1];
        if(otherChargeList.isEmpty()) {
            throw new customException('SalesOrder OtherCharge Id not found with provided ID or does not belong to the Sales Order.');
        } 
        getOtherChargesPendingAmt.put(otherChargeList[0].Id,otherChargeList[0]);
        return getOtherChargesPendingAmt;
    }
    
    public static Map<String,Object> createResult(ReceiptAcknowledgement__c receipt, String message) {
        Map<String,Object> result = new Map<String,Object>();
        result.put('receiptId', receipt.Id);
        result.put('message', message);
        return result;
    }
}