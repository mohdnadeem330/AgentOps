/*
* SR Type : SPA Registration
* Purpose : To call DARI Cancel Appliation API.
*/

global without sharing class CC_SPACancelApplication implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPACancelApplication: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ADMApplicationNumber__c, (select id,Name, SyncStatus__c from HexaBPM__SR_Docs__r) FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];

                List<String> errorsMessages = new List<String>();

                if(userDetail.EmirateId__c == null || userDetail.EmirateId__c == ''){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.USER_EMIRATE_ID_VALIDATION).Message__c);
                }

                List<HexaBPM__SR_Doc__c> documentsList = sRRecord.HexaBPM__SR_Docs__r;
                List<HexaBPM__SR_Doc__c> documentsToUpdate = new List<HexaBPM__SR_Doc__c>();

                for (HexaBPM__SR_Doc__c docRecord : documentsList) {

                    docRecord.SyncStatus__c = '';
                    documentsToUpdate.add(docRecord);
                }
                update documentsToUpdate;

                ADMRegistrationUtility.cancelApplicationFuture(sRRecord.Id);
                
            } 
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPACancelApplication';
        }
        return result;
    }
}