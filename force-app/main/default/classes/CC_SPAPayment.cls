/*
* SR Type : SPA Registration
* Purpose : To call DARI Payment API
*/
global without sharing class CC_SPAPayment implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPAPayment: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,HexaBPM__Summary__c, ADMApplicationNumber__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                String stepStatus = [SELECT Id,HexaBPM__Status__r.Name FROM HexaBPM__Step__c WHERE Id=:stp.Id LIMIT 1].HexaBPM__Status__r.Name;
                User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
                
                List<String> errorsMessages = new List<String>();
                
                if(!sRRecord.Proceed_with_Offline__c && (userDetail.EmirateId__c == null || userDetail.EmirateId__c == '')){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.USER_EMIRATE_ID_VALIDATION).Message__c);
                }
                if(stepStatus != 'Complete Manually' && sRRecord.Proceed_with_Offline__c){
                    return System.Label.ALD_SPA_Offline_Error;
                }
                if(sRRecord.Proceed_with_Offline__c){
                    List<HexaBPM__SR_Doc__c> hrDocList = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: sRRecord.Id AND (HexaBPM__Document_Name__c ='ADM Receipt' OR HexaBPM__Document_Name__c ='SPA Registration Documents') AND HexaBPM__Status__c !='Uploaded'];
                    if(hrDocList.size() > 0 ){
                        errorsMessages.add(System.Label.ALD_SPA_Offline_Doc_Required_Error); 
                    }   
                    
                }
                
                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }
                if(!sRRecord.Proceed_with_Offline__c){  //***** Bypass for Proceed with Offline Process *******//
                    ADMRegistrationUtility.paymentFuture(sRRecord.Id);
                }else{
                    SRUtility.updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.COMPLETED_STATUS, 'Manually Completed');
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPAPayment';
        }
        return result;
    }
}