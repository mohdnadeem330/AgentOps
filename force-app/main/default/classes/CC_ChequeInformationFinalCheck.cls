global without sharing class CC_ChequeInformationFinalCheck implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ChequeInformationFinalCheck: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                List<ReceiptAcknowledgement__c> ra = [Select Id, ReferenceNumber__c, PaymentType__c, MaturityDate__c, BankName__c From ReceiptAcknowledgement__c Where ServiceRequest__c =: sRRecord.Id];

                if(ra.isEmpty()){
                    return 'New Cheque not found.';
                }

                List<String> errorsMessages = new List<String>();

                if(ra[0].ReferenceNumber__c == '' || ra[0].ReferenceNumber__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.RECEIPT_NUMBER_CHEQUE_REPLACE_VALIDATION).Message__c);
                }

                if(ra[0].PaymentType__c == Constants.CHEQUE && ra[0].MaturityDate__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.CHEQUE_REPLACEMENT_MATURITY_DATE_VALIDATION).Message__c);
                }

                if(ra[0].PaymentType__c == Constants.CHEQUE && ra[0].BankName__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.CHEQUE_REPLACEMENT_BANK_NAME_VALIDATION).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }
                
            } 
        } catch(Exception e){
            result = e.getMessage()+e.getLineNumber()+' :CC_ChequeInformationFinalCheck';
        }
        return result;
    }
}