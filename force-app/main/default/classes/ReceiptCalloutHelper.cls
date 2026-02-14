public with sharing class ReceiptCalloutHelper {
    public static void PrepareDataForCallout(List<Id> pcIds){
        List<ReceiptAcknowledgement__c> pcList = ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(pcIds);
        
        // FIN-75: Filter out receipts with StopCallout__c = true from both pcList and pcIds
        List<ReceiptAcknowledgement__c> filteredPcList = new List<ReceiptAcknowledgement__c>();
        List<Id> filteredPcIds = new List<Id>();
        
        for(ReceiptAcknowledgement__c ra : pcList) {
            if(ra.StopCallout__c != true) {
                filteredPcList.add(ra);
                filteredPcIds.add(ra.Id);
            } else {
                System.debug('FIN-75: Skipping ERP callout for receipt ' + ra.Id + ' due to StopCallout__c = true');
            }
        }
        
        // Update pcList and pcIds with filtered data
        pcList = filteredPcList;
        pcIds.clear();
        pcIds.addAll(filteredPcIds);
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> pcdList = new List<Object>();
        
        String reversalERPId = '';
        for (ReceiptAcknowledgement__c ra: pcList) {
            Map<String, Object> pcdMap = new Map<String, Object>();
            
            String recordMode = String.isBlank(ra.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
            
            pcdMap.put('recordMode', recordMode);
            pcdMap.put('recordId', ra.Id); 
            pcdMap.put('createdById', ra.CreatedBy.Email);
            // pcdMap.put('createdById', 'MENAYA@aldar.com');
            pcdMap.put('salesOrderId', ra.SalesOrder__c != null ? ra.SalesOrder__r.ERPID__c : '');
            pcdMap.put('sfSoPayTermId', ra.SalesOrder__c != null ? String.ValueOf(ra.SalesOrder__r.PaymentPlan__c) : '');
            pcdMap.put('chequeNo', ra.ReferenceNumber__c);
            pcdMap.put('unitNo', ra.SalesOrder__c != null && ra.SalesOrder__r.Unit__c != null ? ra.SalesOrder__r.Unit__r.Name : '');
            pcdMap.put('chequeAmt', String.valueOf(ra.Amount__c));
            pcdMap.put('currencyCode', ra.CurrencyIsoCode);
            pcdMap.put('bankName', ra.BankName__c);
            pcdMap.put('branchName', '');
            pcdMap.put('paymentType', ra.PaymentType__c);
            pcdMap.put('subType', ra.PaymentSubType__c);
            pcdMap.put('chequeDate', ra.MaturityDate__c);
            pcdMap.put('remarks', ra.Remarks__c);
            pcdMap.put('chequeReceived', ra.ChequeReceived__c ? 'Y' : 'N');
            pcdMap.put('recReversalReason', ra.StatusReason__c);
            pcdMap.put('isUnidentified', ra.UnidentifiedReceiptFlag__c ? 'Y' : 'N');
            pcdMap.put('glDate', ra.GLDate__c);
            pcdMap.put('RANumber', ra.Name);
            
            system.debug('ra.UnidentifiedReceiptProject__r.Name ');
            pcdMap.put('unidentifiedProject', ra.UnidentifiedReceiptProject__r.Name );  // Add relationshipt name
            pcdMap.put('unidentifiedProjectAccount', ra.UnidentifiedAccountNumber__c);
            
            /*      if(ra.UnidentifiedReceiptAccountType__c == 'Corporate'){
if(ra.UnidentifiedReceiptProject__c != null){
pcdMap.put('unidentifiedProjectAccount', ra.UnidentifiedReceiptProject__r.AccountNumberCorporate__c);
}else{
pcdMap.put('unidentifiedProjectAccount', Label.CorporateAccountNumber);
}
}else if(ra.UnidentifiedReceiptAccountType__c == 'Escrow'){
pcdMap.put('unidentifiedProjectAccount', ra.UnidentifiedReceiptProject__r.AccountNumberEscrow__c);
}
*/            
            
            String receivedBy = '';
            if(ra.PaymentType__c == Constants.ONLINE){
                receivedBy = Label.ReceivedByUserIdForOnline_ERP;
            }else{
                receivedBy = ra.ChequeReceivedBy__r.Email;
            }
            pcdMap.put('chequeReceivedBy', ra.ChequeReceivedBy__c != null ? receivedBy : '');
            pcdMap.put('chequeReceivedDate', ra.ChequeReceivedDate__c);
            pcdMap.put('erpCheckId', ra.ERPID__c);
            pcdMap.put('isHeaderFlag', ra.IsReceiptAcknowledgementChange__c ? 'Y' : 'N');
            pcdMap.put('isLinesFlag', ra.IsReceiptAllocationChange__c ? 'Y' : 'N');
            pcdMap.put('holdDate', ra.HoldDate__c );     // Added by Muzammil as part of receipt remittance - 23 Aug 2022
            pcdMap.put('sfRecStatus', ra.Status__c);    // Added by Muzammil as part of receipt remittance - 23 Aug 2022
            pcdMap.put('isDelete', ra.Markfordeletion__c ? 'Y' : 'N');    // Added by Muzammil to delete receipts - 16th Sept 2022
            
            Decimal iNo = 0;
            String invoiceNo = '';
            List<Object> raLineList = new List<Object>();
            for (ReceiptAllocation__c raLine: ra.Receipt_Allocations__r) {
                if(raLine.TypeOfInvoice__c != 'Adjustment' && raLine.TypeOfInvoice__c != 'WriteOff' 
                   && raLine.SalesOrder__r.Status__c != 'Cancelled' 
                 //  && raLine.SalesOrder__r.Status__c != 'RTO Converted'
                  ){
                       
                    Map<String, Object> raLineMap = new Map<String, Object>();
                    raLineMap.put('recackRecordId', ra.Id);
                    raLineMap.put('erpCheckApplId', raLine.ERPID__c);
                    raLineMap.put('recordId', raLine.Id);
                    raLineMap.put('salesOrderId', raLine.SalesOrder__c != null ? raLine.SalesOrder__r.ERPID__c : '');
                    raLineMap.put('chequeNo', ra.ReferenceNumber__c);
                    //Modified by Dharnesh
                    //raLineMap.put('installmentNo', raLine.InstallmentLine__c != null ? String.valueOf(raLine.InstallmentLine__r.InstallmentNumber__c) : '');
                    raLineMap.put('installmentNo', raLine.InstallmentLine__c != null ? 
                    String.valueOf(raLine.InstallmentLine__r.InstallmentNumber__c) : 
                    (raLine.SalesOrderOtherCharges__c != null && raLine.SalesOrderOtherCharges__r.TypeOfCharge__c != null && 
                      System.Label.TypeOfChargesAutoRemit.contains(raLine.SalesOrderOtherCharges__r.TypeOfCharge__c) && ra.ServiceRequest__c != null?'-1':''));
                    //Modified by Dharnesh
                    raLineMap.put('unitNo', raLine.SalesOrder__c != null && raLine.SalesOrder__r.Unit__c != null ? raLine.SalesOrder__r.Unit__r.Name : '');
                    raLineMap.put('lineAmount', String.valueOf(raLine.AmountApplied__c));
                    if(raLine.SalesOrderOtherCharges__c != null){
                        raLineMap.put('typeOfCharge', raLine.InstallmentNumberOrChargeType__c);
                        raLineMap.put('otherChargeSFID', raLine.SalesOrderOtherCharges__c);
                        raLineMap.put('otherChargeERPID', raLine.SalesOrderOtherCharges__r.InvoiceId__c);// invoice id
                    }
                    // ASF-3279 changes, Auto remittance 
                     if(((raLine.InstallmentLine__c != null && raLine.InstallmentLine__r.InstallmentNumber__c == 1 ) ||
                      (raLine.SalesOrderOtherCharges__c != null && raLine.SalesOrderOtherCharges__r.TypeOfCharge__c != null && 
                      System.Label.TypeOfChargesAutoRemit.contains(raLine.SalesOrderOtherCharges__r.TypeOfCharge__c)) )
                         && ra.PaymentType__c == Constants.ONLINE && ra.status__c == 'Received'  ){//&& ReceiptAcknowledgementTriggerHandler.lstAutoRemittedReceipts.contains(ra.Id) ){ && raLine.Amount__c > 0 
                            
                        pcdMap.put('isAutoRemit','T');
                    } else{
                        pcdMap.put('isAutoRemit','F');
                    }
                    raLineList.add(raLineMap);
                    if (raLine.SalesOrder__c == ra.SalesOrder__c && raLine.InstallmentLine__c != null && iNo < raLine.InstallmentLine__r.InstallmentNumber__c) {
                        iNo = raLine.InstallmentLine__r.InstallmentNumber__c;
                        invoiceNo = raLine.InstallmentLine__r.InvoiceNumber__c;
                    }
                     //added by Dharnesh
                    else if (raLine.SalesOrder__c == ra.SalesOrder__c && (raLine.SalesOrderOtherCharges__c != null && raLine.SalesOrderOtherCharges__r.TypeOfCharge__c != null && 
                      System.Label.TypeOfChargesAutoRemit.contains(raLine.SalesOrderOtherCharges__r.TypeOfCharge__c)) && ra.ServiceRequest__c != null){
                        iNo = -1;
                    }
                    //added by Dharnesh
                }
            }
            pcdMap.put('receiptAppl', raLineList);
            pcdMap.put('installmentNo', iNo != 0 ? String.valueOf(iNo) : '');
            pcdMap.put('transactionId', invoiceNo);
            
            pcdList.add(pcdMap);
            if (String.isBlank(reversalERPId) && ra.ServiceRequest__c != null && ra.ServiceRequest__r.ReceiptAcknowledgement__c != null && ra.ServiceRequest__r.ReceiptAcknowledgement__r.ERPID__c != null) {
                reversalERPId = ra.ServiceRequest__r.ReceiptAcknowledgement__r.ERPID__c;
            }
        }
        finalMap.put('pmtchqRq', pcdList);
        finalMap.put('pmtReversalId', reversalERPId);    // Reversal Receipt ERP Id
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replaceAll(':null', ':""');
        System.debug('requestBody::: ' + requestBody);
        
        if (!pcdList.isEmpty() && System.isFuture() == false) {
            if (System.IsBatch() == true && !Trigger.isExecuting ) { 
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.PAYMENT_CHQ_INTEGRATION, pcIds);
            } else if(!System.IsBatch() && Trigger.isExecuting) {
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.PAYMENT_CHQ_INTEGRATION, pcIds);
            } else if (System.isQueueable()) {
                // In Queueable context, call synchronously (like batch)
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.PAYMENT_CHQ_INTEGRATION, pcIds);
            }
        }
    }
}