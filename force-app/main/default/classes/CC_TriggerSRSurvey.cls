/**********************************************************************************************************************
* Name               : CC_TriggerSRSurvey                                                        
* Description        : This class is used by Handover Process to trigger the survey
* Usage              : Handover 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_TriggerSRSurvey implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_TriggerSRSurvey: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,SRType__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
               HexaBPM__Step__c matchedStep=[select Id,HexaBPM__Summary__c from HexaBPM__Step__c where Id =:stp.Id];
                if(sRRecord.SRType__c==Constants.HANDOVER_RT){
                    sRRecord.Survey_Required__c=true;
                    if(matchedStep.HexaBPM__Summary__c==Constants.HOME_ORIENTATION_LETTER){
                        sRRecord.Survey_Point__c=Constants.HANDOVER_HO;
                    }else if(matchedStep.HexaBPM__Summary__c==Constants.KEY_HANDOVER){
                         sRRecord.Survey_Point__c=Constants.HANDOVER_KH;
                    }      
                    update sRRecord;
                }
               
                //Send CUstomer Survey
              //  System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<Id>{sRRecord.Id}));
            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_TriggerSRSurvey';
        }
        return result;
    }
}