global without sharing class CC_SRTransferValidations implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        
         HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
         SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
       
         if (!serviceRequest.ExemptValidations__c) {
            Decimal thresholdLimit = salesOrder.Unit__r.BuildingSectionName__r.TransferThresholdLimit__c == null ? 0 : (salesOrder.NetAmount__c * (salesOrder.Unit__r.BuildingSectionName__r.TransferThresholdLimit__c / 100)).setScale(2);
            Boolean isError = false;
            String errorMessage = salesOrder.Unit__r.Name + ' Property cannot be transfer because of ';
            if (salesOrder.MortgageApplicable__c == 'Yes') {
                SystemMessages__mdt message = Utilities.getSystemMessages('MORTGAGE_APPLICABLE');
                errorMessage += message.Message__c + ', ';
                isError = true;
            }

            List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
            for (InstallmentLines__c lines : salesOrder.InstallmentLines__r) {
                installmentLinesList.add(lines);
            }
            if(!installmentLinesList.isEmpty()){
                Boolean isUnclearedReceipts = SRUtility.checkForUnclearedReceipts(installmentLinesList);
                isError = isError == true ? true : isUnclearedReceipts;
                SystemMessages__mdt message = Utilities.getSystemMessages('UNCLEARED_RECEIPTS');
                errorMessage += isUnclearedReceipts == true ? message.Message__c + ', ' : '';
            }

            if (!serviceRequest.HexaBPM__Customer__r.TransferThresholdLimitExcluded__c && salesOrder.TotalBilled__c < thresholdLimit) {
                SystemMessages__mdt message = Utilities.getSystemMessages('THRESHOLD_LIMIT');
                errorMessage += message.Message__c + ', ';
                isError = true;
            }

            List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
            for (ReceiptAcknowledgement__c receipts : salesOrder.Payments__r) {
                receiptList.add(receipts);
            }
            if(!receiptList.isEmpty()){
                
                Boolean isOutstandingAmount = SRUtility.checkForOutstandingAmountWithBypass(receiptList, serviceRequest); //SRUtility.checkForOutstandingAmount(receiptList); //SS_FOR_RECEIPT_BYPASS_LOGIC_ASF_514
                isError = isError == true ? true : isOutstandingAmount;
                SystemMessages__mdt message = Utilities.getSystemMessages('OUTSTANDING_PAYMENT');
                errorMessage += isOutstandingAmount == true ? message.Message__c + ', ' : '';
            }

            List<SalesOrderOtherCharges__c> otherChargesList = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherChares : salesOrder.SalesOrdersOtherCharges__r) {
                otherChargesList.add(otherChares);
            }
            if(!otherChargesList.isEmpty()){
                Boolean isLPC = SRUtility.checkLatePaymentCharges(salesOrder.Id);
                isError = isError == true ? true : isLPC;
                SystemMessages__mdt message = Utilities.getSystemMessages('LATE_PAYMENT_CHARGES');
                errorMessage += isLPC == true ? message.Message__c + ', ' : '';
            }
            
            if (isError && String.isNotBlank(errorMessage)) {
                errorMessage = errorMessage.removeEnd(', ');
                System.debug('Error>>> ' + errorMessage);
                return errorMessage;
            }
        }
        
         return Constants.SUCCESS_RETURN_MESSAGE;
    }
}