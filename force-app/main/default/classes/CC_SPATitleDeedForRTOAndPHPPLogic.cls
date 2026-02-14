/*
* SR Type : SPA & Title Deed For RTO And PHPP Logic
* Purpose : To run all custom code from one class.
*/
global without sharing class CC_SPATitleDeedForRTOAndPHPPLogic implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPATitleDeedForRTOAndPHPPLogic: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Name, HexaBPM__External_Status_Name__c, Unit__c, HexaBPM__Parent_SR__c, HandoverDetail__c, HexaBPM__SR_Template__r.Name, MortgageApplicable__c, MortgageApplicationNumber__c, MortgageConfirmationDate__c, MortgageAmount__c, MortgageBank__c, MortgageRegistrationFees__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c Limit 1];
                
                List<String> errorsMessages = new List<String>();

                if(stp.HexaBPM__Summary__c == 'CM Validation' && stp.HexaBPM__Step_Status__c == 'Completed'){
                    if(sRRecord.MortgageApplicable__c == 'Yes' && (sRRecord.MortgageApplicationNumber__c == null || sRRecord.MortgageConfirmationDate__c == null || sRRecord.MortgageAmount__c == null || String.isBlank(sRRecord.MortgageBank__c) || sRRecord.MortgageRegistrationFees__c == null)){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.MORTGAGE_DETAILS_VALIDATION).Message__c);
                    }

                } else if(stp.HexaBPM__Summary__c == 'CM Validation' && sRRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED){
                    errorsMessages = submitSRLogic(sRRecord);
                }
                
                if(!errorsMessages.isEmpty()){
                    String errorString = errorsMessages.toString();
                    return errorString.substring(1,errorString.length()-1).replace(',',' | ');
                }
            }
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPATitleDeedForRTOAndPHPPLogic';
        }
        return result;
    }

    /*
    *  To validate and populate Handover SR & Handover Details based on unit when SR is submitted.
    * 
    */
    public static List<String> submitSRLogic(HexaBPM__Service_Request__c sRRecord) {

        List<String> errorsMessages = new List<String>();

        List<HexaBPM__Service_Request__c> handoverSR = [Select Id, HandoverDetail__c, HexaBPM__External_Status_Name__c From HexaBPM__Service_Request__c Where Unit__c =: sRRecord.Unit__c And HexaBPM__External_Status_Name__c != 'Cancelled' and SRType__c =: Constants.HANDOVER_RT ORDER BY CreatedDate DESC];

        if(handoverSR.isEmpty()){
            errorsMessages.add(Utilities.getSystemMessages(Constants.HANDOVER_SR_NOT_FOUND).Message__c);
            return errorsMessages;
        }

        sRRecord.HexaBPM__Parent_SR__c = handoverSR[0].Id;
        sRRecord.HandoverDetail__c = handoverSR[0].HandoverDetail__c;
        update sRRecord;

        return errorsMessages;
    }
}