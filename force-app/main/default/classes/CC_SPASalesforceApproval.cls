/*
* SR Type : SPA Registration
* Purpose : To call DARI Status Approval API
*/
global without sharing class CC_SPASalesforceApproval implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPASalesforceApproval: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ADMApplicationNumber__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                if(stp.HexaBPM__Summary__c != 'ADM Team Approval'){
                    User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
                    
                    List<String> errorsMessages = new List<String>();
                    
                    if(!sRRecord.Proceed_with_Offline__c && (userDetail.EmirateId__c == null || userDetail.EmirateId__c == '')){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.USER_EMIRATE_ID_VALIDATION).Message__c);
                    }
                    
                    if(!errorsMessages.isEmpty()){
                        return errorsMessages.toString().replace(',','\n');
                    }
                }
                String approvalStatus = stp.HexaBPM__Step_Status__c == Constants.STEP_ACCEPTED_STATUS ? 'true' : 'false';
                if(stp.HexaBPM__Summary__c != 'ADM Team Approval' && !sRRecord.Proceed_with_Offline__c){  //***** Bypass for Proceed with Offline Process *******//
                    
                    ADMRegistrationUtility.sendApprovalStatusFuture(sRRecord.Id, approvalStatus);
                }else{
                    if(approvalStatus == 'true'){
                        SRUtility.updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.STATUS_APPROVED, 'Approved');
                    }else{
                        SRUtility.updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.PENDING_STATUS, 'Rejected');
                    }
                }
            } 
        } catch(Exception e){
            System.debug('Message:'+ e.getMessage());
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPASalesforceApproval';
        }
        return result;
    }
}