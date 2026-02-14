/*
* SR Type : RTO Extension
* Purpose : To validate the request and its contains all the logic
*/
global without sharing class CC_RTOExtensionSRLogic implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_RTOExtensionSRLogic: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ForfeitAmount__c, Refund_Amount__c, PaymentExtensionDate__c, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.OutstandingAmount__c, ReceiptAcknowledgement__r.MaturityDate__c, SalesOrder__c, PaymentExtensionPeriod__c, SummaryReport__c, ExemptValidations__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                List<String> errorsMessages = new List<String>();

                if(stp.HexaBPM__Summary__c == 'Verify the Request'){
                    errorsMessages = verifyTheRequestLogic(sRRecord, stp);
                }

                if(stp.HexaBPM__Summary__c == 'Approval by EDCC' || stp.HexaBPM__Summary__c == 'Approval by Development Finance'){
                    approveTheRequestLogic(sRRecord, stp);
                }
                
                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',',' | ');
                }
            }
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_RTOExtensionSRLogic';
        }
        return result;
    }

    public static List<String> verifyTheRequestLogic(HexaBPM__Service_Request__c sRRecord, HexaBPM__Step__c stp) {

        List<String> errorsMessages = new List<String>();

        if(sRRecord.ReceiptAcknowledgement__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.RECEIPT_ACKNOWLEDGEMENT_SR_VALIDATION).Message__c);
        } else {
            if(sRRecord.ReceiptAcknowledgement__r.MaturityDate__c == null){
                errorsMessages.add(Utilities.getSystemMessages(Constants.RECEIPT_ACKNOWLEDGEMENT_MATURITY_DATE_EX).Message__c);
            } else {
                if(sRRecord.PaymentExtensionDate__c != null){
                    Integer monthDiff = sRRecord.ReceiptAcknowledgement__r.MaturityDate__c.monthsBetween(sRRecord.PaymentExtensionDate__c);
                    
                if (sRRecord.PaymentExtensionDate__c.day() >= sRRecord.ReceiptAcknowledgement__r.MaturityDate__c.day()) {
                    monthDiff++;
                }
    
                sRRecord.PaymentExtensionPeriod__c = monthDiff;
                update sRRecord;
                }
            }
        }
        if(sRRecord.PaymentExtensionDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.PAYMENT_EXTENSION_DATE_SR_VALIDATION).Message__c);
        }
        if(stp.HexaBPM__Step_Status__c == 'Generate CCA'){
            if(sRRecord.ForfeitAmount__c == null && sRRecord.Refund_Amount__c == null){
                errorsMessages.add(Utilities.getSystemMessages(Constants.PAYMENT_EXTENSION_AMOUNT_SR_VALIDATION).Message__c);
            }
        }
        if(sRRecord.ReceiptAcknowledgement__c != null && sRRecord.ReceiptAcknowledgement__r.Status__c == Constants.RECEIPT_STATUS_CLEARED){
            errorsMessages.add(Utilities.getSystemMessages(Constants.CLEARED_RECEIPTS_ERROR).Message__c);
        }

        return errorsMessages;
        /*List<InstallmentLines__c> installmentLinesList = [SELECT Id, Name, InstallmentNumber__c, InstallmentDate__c FROM InstallmentLines__c WHERE SalesOrder__c =: sRRecord.SalesOrder__c];

        //---- To validate if the installment date not exceed the next installment
        for (InstallmentLines__c il : installmentLinesList) {
            if(il.InstallmentNumber__c == sRRecord.InstallmentLine__r.InstallmentNumber__c+1){
                if(sRRecord.PaymentExtensionDate__c > il.InstallmentDate__c && sRRecord.ExemptValidations__c == false){
                    return 'Payment Extension Date cannot exceed the next payment installment date. (next payment installment date: '+il.InstallmentDate__c+').';
                }
            }
        }*/
    }

    public static void approveTheRequestLogic(HexaBPM__Service_Request__c sRRecord, HexaBPM__Step__c stp) {

        if(stp.Step_Template_Code__c == 'Approval by Development Finance' && sRRecord.PaymentExtensionPeriod__c > 2){
            HexaBPM__SR_Status__c srStatus = [Select Id From HexaBPM__SR_Status__c Where Name = 'Approved' LIMIT 1];
            sRRecord.HexaBPM__External_SR_Status__c =  srStatus.Id;
            sRRecord.HexaBPM__Internal_SR_Status__c =  srStatus.Id;
            update sRRecord;
        }
        else{
            ReceiptAcknowledgement__c receiptRec = new ReceiptAcknowledgement__c(Id=sRRecord.ReceiptAcknowledgement__c, MaturityDate__c=sRRecord.PaymentExtensionDate__c);
            update receiptRec;
            //PaymentExtensionCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        }
    }
}