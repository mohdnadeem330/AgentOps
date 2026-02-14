public with sharing class CancellationCalloutHelper {
	public static String ApprovalStatus = 'Closed';

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);        
        prepareDataForCallout(serviceRequestList);
    }
    
    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        List<Id> salesOrderIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
            salesOrderIds.add(serviceRequest.SalesOrder__c);
        }
         
        Map<Id, HexaBPM__Service_Request__c> serviceRequestMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, (SELECT Id, HexaBPM__Summary__c, Owner.Email, HexaBPM__Closed_Date__c FROM HexaBPM__Steps_SR__r ORDER BY LastModifiedDate DESC LIMIT 1) FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);
		
        List<SalesOrder__c> salesOrderList = SalesOrderService.queryAllFieldsWithExtraFields(salesOrderIds);
        Map<Id, List<SalesOrderOtherCharges__c>> otherChargeMap = new Map<Id, List<SalesOrderOtherCharges__c>>();
        for (SalesOrder__c so: salesOrderList) {
            List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherCharge: so.SalesOrdersOtherCharges__r) {
                otherChargeList.add(otherCharge);
            }
            otherChargeMap.put(so.Id, otherChargeList);
        }
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> cancellationReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> cancellationReqMap = new Map<String, Object>();
            
            cancellationReqMap.put('srSfid', serviceRequest.Id);
            cancellationReqMap.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            cancellationReqMap.put('cancelReqDate', date.newinstance(serviceRequest.CreatedDate.year(), serviceRequest.CreatedDate.month(), serviceRequest.CreatedDate.day()));
            cancellationReqMap.put('cancellationStatus', serviceRequest.HexaBPM__External_Status_Name__c);
            cancellationReqMap.put('cancelReason', serviceRequest.CancellationReason__c);
            cancellationReqMap.put('otherReason', serviceRequest.SocialReason__c);
            cancellationReqMap.put('refundApplicable', serviceRequest.RefundAmount__c != null && serviceRequest.RefundAmount__c > 0 ? 'Y' : 'N');
            cancellationReqMap.put('refundReason', '');
            cancellationReqMap.put('refundAmount', serviceRequest.RefundAmount__c != null ? String.valueOf(serviceRequest.RefundAmount__c) : '');
            cancellationReqMap.put('forfeitureAmount', serviceRequest.ForfeitAmount__c != null ? String.valueOf(serviceRequest.ForfeitAmount__c) : '');
           	cancellationReqMap.put('ProvisionFund', serviceRequest.Provision_Fund__c != null ? String.valueOf(serviceRequest.Provision_Fund__c) : '');
            cancellationReqMap.put('reallocatedAmount', serviceRequest.ReallocationAmount__c != null ? String.valueOf(serviceRequest.ReallocationAmount__c) : '');
            cancellationReqMap.put('option', serviceRequest.CancellationOption__c);// SS_JSON_IMPLEMENTATION
            cancellationReqMap.put('comments', serviceRequest.ServiceRequestComments__c);// SS_JSON_IMPLEMENTATION
            cancellationReqMap.put('agreementType', serviceRequest.AgreementType__c);// SS_JSON_IMPLEMENTATION
            cancellationReqMap.put('receivedAmount', serviceRequest.TotalCollectedAmount__c); // SS_JSON_IMPLEMENTATION on 17-Jul-23 Need confirmation from Venu
            cancellationReqMap.put('priceRevisionReq', serviceRequest.PriceRevisionRequired__c ? 'Y' : 'N'); // SS_JSON_IMPLEMENTATION on 17-Jul-23 Need confirmation from Venu
            cancellationReqMap.put('srStatus', ApprovalStatus); // SS_JSON_IMPLEMENTATION on 17-Jul-23 Need confirmation from Venu
            
            //check cancellation step is Approval by Finance
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-START
            HexaBPM__Service_Request__c sr = serviceRequestMap.get(serviceRequest.Id);
            if(!sr.HexaBPM__Steps_SR__r.isEmpty()) {
                HexaBPM__Step__c step = sr.HexaBPM__Steps_SR__r[0];
                if(step.HexaBPM__Summary__c == 'Cancellation Approval by Finance') {
                    cancellationReqMap.put('approvaldate', String.valueOf(step.HexaBPM__Closed_Date__c));
                    cancellationReqMap.put('approvedby', step.Owner.Email);
                }
            }
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END
            //serviceRequestMap.get(serviceRequest.Id).HexaBPM__Summary__c == 'Cancellation Approval by Finance'

            List<Object> othChgList = new List<Object>();
            if (otherChargeMap.containsKey(serviceRequest.SalesOrder__c)) {
                for (SalesOrderOtherCharges__c otherCharge: otherChargeMap.get(serviceRequest.SalesOrder__c)) {
                    if (otherCharge.ERPID__c == null && (otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE || otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_CANCELLATION_FEE || otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO)) {
                        Map<String, Object> othChgMap = new Map<String, Object>();

                        othChgMap.put('srSfid', serviceRequest.Id);
                        othChgMap.put('sfId', otherCharge.Id);
                        othChgMap.put('name', otherCharge.Name);
                        othChgMap.put('currencyCode', otherCharge.CurrencyIsoCode);
                        othChgMap.put('sfSalesOrderId', otherCharge.SalesOrder__c);
                        othChgMap.put('accountId', otherCharge.Account__c);
                        othChgMap.put('amountReceived', otherCharge.AmountReceived__c != null ? String.valueOf(otherCharge.AmountReceived__c) : '');
                        othChgMap.put('amount', otherCharge.Amount__c != null ? String.valueOf(otherCharge.Amount__c) : '');
                        othChgMap.put('invoiceId', otherCharge.InvoiceId__c);
                        othChgMap.put('invoiceNumber', otherCharge.InvoiceNumber__c);
                        othChgMap.put('opportunity', otherCharge.Opportunity__c);
                        othChgMap.put('outAmountWords', otherCharge.OutstandingAmountinwords__c);
                        othChgMap.put('typeOfCharge', otherCharge.TypeOfCharge__c);
                        othChgMap.put('salesSupportCost', otherCharge.SalesSupportCost__c != null ? String.valueOf(otherCharge.SalesSupportCost__c) : '');
                        othChgMap.put('installmentLine', '');
                        othChgMap.put('amountWithoutVat', otherCharge.AmountWithoutVAT__c != null ? String.valueOf(otherCharge.AmountWithoutVAT__c) : '');
                        othChgMap.put('vatAmount', otherCharge.VATAmount__c != null ? String.valueOf(otherCharge.VATAmount__c) : '');
                        othChgMap.put('subType', otherCharge.SubType__c);

                        othChgList.add(othChgMap);
                    }
                }
            }
            cancellationReqMap.put('othChg', othChgList);

            cancellationReqList.add(cancellationReqMap);
        }
        finalMap.put('cancelRq', cancellationReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!cancellationReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.CANCELLATION_INTEGRATION, srIds));
        }
    }

    public static void processCancellationResponse(MulePOSSingleResponseWrapper.results results, String processName, String requestBody, String muleRes) {
        System.debug('processCancellationResponse -> ');
        List<String> srIds = new List<String>();
        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        
        List<String> invoiceNoSet = new List<String>();
        Map<String, String> creditNoteMap = new Map<String, String>();
        
        if(results.cancellationRes!=null) {
            for (MulePOSSingleResponseWrapper.CancellationRes responseRecord: results.cancellationRes) {
                if (responseRecord.status == Constants.MULESOFT_FAILURE){
                    srIds.add(responseRecord.srSFId);
                }
            }
            Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);
            
            List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
            List<Logger__c> loggerList = new List<Logger__c>();
            for (MulePOSSingleResponseWrapper.CancellationRes responseRecord: results.cancellationRes) {
                HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
                if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                    srRecord.Id = responseRecord.srSFId;
                    srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    // srRecord.ERPID__c = responseRecord.srERPId;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = 0;
                    srRecord.ErrorReason__c = '';
                    srSuccessList.add(srRecord);
                } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                    srRecord.Id = responseRecord.srSFId;
                    srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = srMap.get(responseRecord.srSFId).RetryCount__c == null ? 1 : srMap.get(responseRecord.srSFId).RetryCount__c + 1;
                    srRecord.ErrorReason__c = responseRecord.errorMsg;
                    srFailedList.add(srRecord);
                    //loggerList.add(LoggerService.addApexServiceCalls('CancellationCalloutHelpers', 'processCancellationResponse', processName, requestBody, muleRes, responseRecord.srSFId));
                }
                System.debug('###loggerList');
                loggerList.add(LoggerService.addApexServiceCalls('CancellationCalloutHelpers', 'processCancellationResponse', processName, requestBody, muleRes, responseRecord.srSFId));
                System.debug('###loggerList');
                for (MulePOSSingleResponseWrapper.OthChgRes responseRecord_oc : responseRecord.othChgRes) {
                    SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
                    otherCharge.Id = responseRecord_oc.sfId;
                    otherCharge.ERPID__c = responseRecord_oc.erpId;
                    otherCharge.ReceivableAccount__c = responseRecord_oc.recAcct;
                    otherCharge.RevenueAccount__c = responseRecord_oc.expAcct;
                    otherCharge.TaxAccount__c = responseRecord_oc.taxAcct;
                    otherCharge.InvoiceNumber__c = responseRecord_oc.invoiceNo;
                    otherChargeList.add(otherCharge);
                }
                
                for (MulePOSSingleResponseWrapper.CreditNoteRes responseRecord_cn : responseRecord.creditNoteRes) {
                    if (String.isNotBlank(responseRecord_cn.invoiceId)) {
                        invoiceNoSet.add(responseRecord_cn.invoiceId);
                        creditNoteMap.put(responseRecord_cn.invoiceId, responseRecord_cn.cnErpId);
                    }
                }
            }
            
            if (!otherChargeList.isEmpty()) {
                update otherChargeList;
            }
            
            System.debug('invoiceNoSet>>>' + invoiceNoSet);
            List<ReceiptAllocation__c> receiptAllocationList = [SELECT Id, Name, ReceiptAcknowledgement__c, InstallmentLine__c, InstallmentLine__r.InvoiceId__c FROM ReceiptAllocation__c 
                                                                WHERE InstallmentLine__c != null AND ReceiptAcknowledgement__r.PaymentType__c =: Constants.PAYMENT_TYPE_CREDIT_NOTE 
                                                                AND ReceiptAcknowledgement__r.PaymentSubType__c =: Constants.PAYMENT_SUB_TYPE_INSTALLMENT_REVERSAL 
                                                                AND InstallmentLine__r.InvoiceId__c != null AND InstallmentLine__r.InvoiceId__c IN: invoiceNoSet];
            
            List<ReceiptAcknowledgement__c> updateReceiptAcknowledgementList = new List<ReceiptAcknowledgement__c>();
            for (ReceiptAllocation__c receiptAllocation: receiptAllocationList) {
                if (creditNoteMap.containsKey(receiptAllocation.InstallmentLine__r.InvoiceId__c)) {
                    ReceiptAcknowledgement__c updateReceiptAcknowledgement = new ReceiptAcknowledgement__c();
                    updateReceiptAcknowledgement.Id = receiptAllocation.ReceiptAcknowledgement__c;
                    updateReceiptAcknowledgement.ERPID__c = creditNoteMap.get(receiptAllocation.InstallmentLine__r.InvoiceId__c);
                    updateReceiptAcknowledgement.SyncStatus__c = Constants.STATUS_SYNCED;
                    updateReceiptAcknowledgement.SyncTime__c = Datetime.now();
                    updateReceiptAcknowledgementList.add(updateReceiptAcknowledgement);
                }
            }
            if (!updateReceiptAcknowledgementList.isEmpty()) {
                update updateReceiptAcknowledgementList;
            }
            
            if (!srSuccessList.isEmpty()) {
                update srSuccessList;
            }
            
            if (!srFailedList.isEmpty()) {
                update srFailedList;
            }
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        } else {
            system.debug('results.cancellationRes is '+results.cancellationRes);
        }
    }
}