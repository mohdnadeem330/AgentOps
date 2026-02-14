/*
* SR Type : Payment Plan Change
* Purpose : to validate if ADM other charge is paid
*/
global without sharing class CC_PPCPayADMCharges implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PPCPayADMCharges: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, SalesOrder__c, SalesOrder__r.ADMFeeStatus__c, ProposalPaymentPlan__c
                 FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                 List<String> errorsMessages = new List<String>();

                if(sRRecord.ProposalPaymentPlan__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.PROPOSAL_PAYMENT_PLAN_VALIDATION).Message__c);
                }
                if(sRRecord.SalesOrder__r.ADMFeeStatus__c > 0){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.ADM_CHARGE_NOT_PAID).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }

                

            } 
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_PPCPayADMCharges';
        }
        return result;
    }
}