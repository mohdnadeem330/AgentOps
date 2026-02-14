/*
* Purpose: Validating Sales orders details like Outstanding Amount, Uncleared Receipts & Late Payment Charges. Performing actions after Finance approval
* SR Type: Mortgage Registration
*/
global without sharing class CC_SRMortgageRegistrationController implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        
        string result ='Success';

        try{        
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        
        String errorMessage = 'To proceed to the next step';
        Boolean isError = false;

        List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
        for (InstallmentLines__c lines : salesOrder.InstallmentLines__r) {
            installmentLinesList.add(lines);
        }

        //Check Installment lines for Uncleared Receipts
        if(!installmentLinesList.isEmpty()){

            Boolean hasUnclearedReceipt = SRUtility.checkForUnclearedReceipts(installmentLinesList);
            if(hasUnclearedReceipt)
            {
                SystemMessages__mdt unclearedReceipts = Utilities.getSystemMessages('UNCLEARED_RECEIPTS');
                errorMessage += ' '+unclearedReceipts.Message__c+',';
                isError = true;
            }
        }

        List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
        for (ReceiptAcknowledgement__c receipts : salesOrder.Payments__r) {
            receiptList.add(receipts);
        }

        //Check Receipts for Outstanding payments
        if(!receiptList.isEmpty()){
            Boolean hasOutStandingPayment = SRUtility.checkForOutstandingAmount(receiptList);
            if(hasOutStandingPayment)
            {
                SystemMessages__mdt outstandingPayment = Utilities.getSystemMessages('OUTSTANDING_PAYMENT');
                errorMessage += ' '+outstandingPayment.Message__c+',';
                isError = true;
            }
                
        }

        List<SalesOrderOtherCharges__c> otherChargesList = new List<SalesOrderOtherCharges__c>();
        for (SalesOrderOtherCharges__c otherChares : salesOrder.SalesOrdersOtherCharges__r) {
            otherChargesList.add(otherChares);
        }

        //Check if Sales order have any Late Payment charges
        if(!otherChargesList.isEmpty()){
            Boolean hasLatePaymentCharges = SRUtility.checkLatePaymentCharges(salesOrder.Id);
            if(hasLatePaymentCharges){
                SystemMessages__mdt latePaymentCharges = Utilities.getSystemMessages('LATE_PAYMENT_CHARGES');
                errorMessage += ' '+latePaymentCharges.Message__c+',';
                isError = true;
            }
        }

        //Actions After SR is Approved by Finance 
        if(serviceRequest.HexaBPM__External_Status_Name__c == 'Approved by Finance'){
            salesOrder.MortgageApplicable__c = 'Yes';
            salesOrder.MortgageBank__c = serviceRequest.MortgageBank__r.Name;
            salesOrder.MortgageAmount__c = serviceRequest.MortgageAmount__c;
            salesOrder.MortgageStartDate__c = serviceRequest.StartDate__c;
            salesOrder.MortgageApplicationNumber__c = serviceRequest.MortgageApplicationNumber__c;
            salesOrder.MortgageBankAccount__c = serviceRequest.MortgageBank__c;

            if(serviceRequest.Receipt_Acknowledgements__r.size() > 0){
                SalesOrderOtherCharges__c soOtherCharges = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.OTHER_CHARGES_TYPE_MORTGAGE_REGISTRATION_CHARGE); 
                ReceiptAllocation__c allocationRecord = SRUtility.createReceiptAllocation(soOtherCharges, serviceRequest);  
            }            

            update salesOrder;

            MortgageCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        }

        if (isError && String.isNotBlank(errorMessage)) {
            errorMessage = errorMessage.removeEnd(',');
            System.debug('Error>>> ' + errorMessage);
            return errorMessage;
        }
    } catch(Exception e){
        result = e.getMessage()+' :CC_SRMortgageRegistrationController '+e.getLineNumber();
        System.debug('line no '+e.getLineNumber());
    }
        return result;
    }
}