/*
* SR Type : Payment Extension
* Purpose : To validate if the requried fields like Installment Line, Exstension Date are filled in and to validate the date provided
*/
global without sharing class CC_VerifyExtensionRequest implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_VerifyExtensionRequest: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ForfeitAmount__c, Refund_Amount__c, PaymentExtensionDate__c, InstallmentLine__c, InstallmentLine__r.InstallmentDate__c, InstallmentLine__r.InstallmentNumber__c, 
                InstallmentLine__r.OutstandingAmount__c, SalesOrder__c, PaymentExtensionPeriod__c, SummaryReport__c, ExemptValidations__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                List<String> errorsMessages = new List<String>();

                if(sRRecord.InstallmentLine__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.INSTALLMENT_LINE_VALIDATION).Message__c);
                }
                if(sRRecord.PaymentExtensionDate__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.PAYMENT_EXTENSION_DATE_SR_VALIDATION).Message__c);
                }
                if(stp.HexaBPM__Step_Status__c == 'Generate CCA'){
                    if(sRRecord.ForfeitAmount__c == null && sRRecord.Refund_Amount__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.PAYMENT_EXTENSION_AMOUNT_SR_VALIDATION).Message__c);
                    }
                }
                if(sRRecord.InstallmentLine__c != null && sRRecord.InstallmentLine__r.OutstandingAmount__c < 100){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.OUTSTANDING_AMOUNT_LESS_100).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',',' | ');
                }

                Integer monthDiff = sRRecord.InstallmentLine__r.InstallmentDate__c.monthsBetween(sRRecord.PaymentExtensionDate__c);
                Integer daysDiff = sRRecord.InstallmentLine__r.InstallmentDate__c.daysBetween(sRRecord.PaymentExtensionDate__c);

                if (sRRecord.PaymentExtensionDate__c.day() >= sRRecord.InstallmentLine__r.InstallmentDate__c.day()) {
                    monthDiff++;
                }

                sRRecord.PaymentExtensionPeriod__c = monthDiff;
                sRRecord.Payment_Extension_Period_In_Days__c = daysDiff;
                update sRRecord;

                List<InstallmentLines__c> installmentLinesList = [SELECT Id, Name, InstallmentNumber__c, InstallmentDate__c FROM InstallmentLines__c WHERE SalesOrder__c =: sRRecord.SalesOrder__c];

                //---- To validate if the installment date not exceed the next installment
                for (InstallmentLines__c il : installmentLinesList) {
                    if(il.InstallmentNumber__c == sRRecord.InstallmentLine__r.InstallmentNumber__c+1){
                        if(sRRecord.PaymentExtensionDate__c > il.InstallmentDate__c && sRRecord.ExemptValidations__c == false){
                            return 'Payment Extension Date cannot exceed the next payment installment date. (next payment installment date: '+il.InstallmentDate__c+').';
                        }
                    }
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_VerifyExtensionRequest';
        }
        return result;
    }
}