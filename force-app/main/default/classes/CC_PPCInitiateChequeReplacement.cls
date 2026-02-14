/*
* SR Type : Payment Plan Change
* Purpose : To submit Cheque Replacement SR in case if there any modification on the exsisting installments and the ChequeReplacementStatus__c is applicable.
*/
global without sharing class CC_PPCInitiateChequeReplacement implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PPCInitiateChequeReplacement: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ProposalPaymentPlan__c, ChequeReplacementStatus__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                 List<String> errorsMessages = new List<String>();

                if(sRRecord.ProposalPaymentPlan__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.PROPOSAL_PAYMENT_PLAN_VALIDATION).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }

                //--- get all Cheque Replacement SR 
                List<HexaBPM__Service_Request__c> ChequeSRToSubmit = [Select Id, HexaBPM__Parent_SR__c, HexaBPM__External_Status_Name__c From HexaBPM__Service_Request__c where HexaBPM__Parent_SR__c =: sRRecord.Id];
                HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
                List<HexaBPM__Service_Request__c> srToUpdate = new List<HexaBPM__Service_Request__c>();

                Integer closedSR = 0;

                for (HexaBPM__Service_Request__c record : ChequeSRToSubmit) {
                    if(record.HexaBPM__External_Status_Name__c == Constants.SR_STATUS_DRAFT){
                        record.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                        record.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
                        record.HexaBPM__Submitted_DateTime__c = system.now();
                        record.HexaBPM__Submitted_Date__c = system.today();
                        srToUpdate.add(record);

                    } else if(record.HexaBPM__External_Status_Name__c == Constants.CLOSED_SR){
                        closedSR = closedSR + 1;
                    }
                }
                if (srToUpdate.size() > 0 ) {
                    update srToUpdate;
                
                //--- check the ChequeReplacementStatus__c
                } else if(stp.HexaBPM__Step_Status__c == 'Cheques Received'){//(ChequeSRToSubmit.size > 0 && srToUpdate.size() == 0) {
                    
                    if(sRRecord.ChequeReplacementStatus__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.PPC_CHEQUE_REPLACEMENT_APPLICABILITY).Message__c);
                        return errorsMessages.toString().replace(',','\n');
                    } else if(sRRecord.ChequeReplacementStatus__c == Constants.CHEQUE_REPLACEMENT_APPLICABLE){
                        if(ChequeSRToSubmit.size() != closedSR){
                            errorsMessages.add(Utilities.getSystemMessages(Constants.PPC_CHEQUE_REPLACEMENT_NOT_CLOSED).Message__c);
                            return errorsMessages.toString().replace(',','\n');
                        }
                    }
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_PPCApproveTheRequest';
        }
        return result;
    }
}