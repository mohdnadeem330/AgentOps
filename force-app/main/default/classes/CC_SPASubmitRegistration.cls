/*
* SR Type : SPA Registration
* Purpose : To validate if the requried Documents are uploaded to DARI and to call DARI Submit Appliation API
*/
global without sharing class CC_SPASubmitRegistration implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPASubmitRegistration: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ADMApplicationNumber__c,Proceed_with_Offline__c, (select id,Name, SyncStatus__c from HexaBPM__SR_Docs__r) FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];

                List<String> errorsMessages = new List<String>();

                if(!sRRecord.Proceed_with_Offline__c && (userDetail.EmirateId__c == null || userDetail.EmirateId__c == '')){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.USER_EMIRATE_ID_VALIDATION).Message__c);
                }
                if(!sRRecord.Proceed_with_Offline__c){
                for (HexaBPM__SR_Doc__c docRecord : sRRecord.HexaBPM__SR_Docs__r) {
                    if(docRecord.SyncStatus__c != Constants.STATUS_SYNCED){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.DOCUMENTS_NEED_TO_REUPLOAD).Message__c);
                        break;
                    }
                }
                }

                if(!errorsMessages.isEmpty()){
                    String errorString = errorsMessages.toString();
                    return errorString.substring(1,errorString.length()-1).replace(',',' | ');
                }
                if(!sRRecord.Proceed_with_Offline__c){  //***** Bypass for Proceed with Offline Process *******//
                	ADMRegistrationUtility.submitApplicationFuture(sRRecord.Id);
                }else{
                     SRUtility.updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.COMPLETED_STATUS, result);
                }

            } 
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPASubmitRegistration';
        }
        return result;
    }
}