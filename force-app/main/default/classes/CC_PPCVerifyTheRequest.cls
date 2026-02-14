/*
* SR Type : Payment Plan Change
* Purpose : To validate if the requried fields like Proposal Payment Plan, Cheque Replacement Status are filled
*/
global without sharing class CC_PPCVerifyTheRequest implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PPCVerifyTheRequest: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ProposalPaymentPlan__c, ChequeReplacementStatus__c
                 FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                 List<String> errorsMessages = new List<String>();

                if(sRRecord.ProposalPaymentPlan__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.PROPOSAL_PAYMENT_PLAN_VALIDATION).Message__c);
                }
                if(sRRecord.ChequeReplacementStatus__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.CHEQUE_REPLACEMENT_STATUS_PPC_VALIDATION).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }
                
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_PPCVerifyTheRequest';
        }
        return result;
    }
}