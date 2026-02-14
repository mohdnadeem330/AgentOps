/*
* SR Type : SPA Registration
* Purpose : To validate if the requried fields are filled in and to call DARI Draft Appliation API
*/
global without sharing class CC_SPAVerifyDetails implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPAVerifyDetails: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ADMApplicationNumber__c, SalesOrder__c, RegistrationDate__c, PaymentDate__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                if(stp.HexaBPM__Summary__c == 'Verify Details' || stp.HexaBPM__Summary__c == 'ReVerify Details'){

                    User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];

                    List<String> errorsMessages = ADMRegistrationUtility.validateRegistrationAttributes(sRRecord.Id);
                    if(!sRRecord.Proceed_with_Offline__c && (userDetail.EmirateId__c == null || userDetail.EmirateId__c == '')){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.USER_EMIRATE_ID_VALIDATION).Message__c);
                    }
        
                    if(!errorsMessages.isEmpty()){
                        return errorsMessages.toString().replace(',',' | ');
                    }
                    if(!sRRecord.Proceed_with_Offline__c){ //***** For proceed with Offline - DARI ******//
                    	ADMRegistrationUtility.createApplication(sRRecord.Id);
                    }else{
                        SRUtility.updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.COMPLETED_STATUS, 'Draft Application Completed');
                        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.COMPLETED_STATUS LIMIT 1];
            			sRRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                        sRRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
                        update sRRecord;
                        
                        
                    }

                } else if(stp.HexaBPM__Summary__c == 'Verify and Close'){

                    List<String> errorsMessages = new List<String>();

                    if(sRRecord.RegistrationDate__c == null || sRRecord.PaymentDate__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.SPA_COMPLETION_DETAILS_VALIDATION).Message__c);
                    }

                    SalesOrder__c so = new SalesOrder__c(Id = sRRecord.SalesOrder__c);
                    so.SPARegistrationStatus__c = 'Registered';
                    update so;
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPAVerifyDetails';
        }
        return result;
    }
}