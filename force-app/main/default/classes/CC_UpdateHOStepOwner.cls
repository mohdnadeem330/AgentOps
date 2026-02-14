/**********************************************************************************************************************
* Name               : CC_UpdateHOStepOwner                                                       
* Description        : This class is used to associate the owner for the step and SR 
* Usage              : Handover 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_UpdateHOStepOwner implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_UpdateHOStepOwner: Invalid SR or SR Step';
            } else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,OwnerID,HandoverDetail__c,HandoverDetail__r.OwnerId,HandoverDetail__r.HandoverAgent__c, HOKAR__c, HOAgent__c, HexaBPM__Record_Type_Name__c, HexaBPM__Parent_SR__c, HexaBPM__Parent_SR__r.HOKAR__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                HexaBPM__Step__c stepRecord = [select id,HexaBPM__Step_Status__c,Step_Template_Code__c from HexaBPM__Step__c where id = :stp.Id limit 1];
                HandoverDetails__c hoDetails= new HandoverDetails__c(Id = sRRecord.HandoverDetail__c);
                if(sRRecord.HexaBPM__Record_Type_Name__c == Constants.SPA_TITLEDEED_FOR_RTP_AND_PHPP_DEV_RT){
                    stepRecord.OwnerID = sRRecord.HexaBPM__Parent_SR__r.HOKAR__c;
                    sRRecord.OwnerID = sRRecord.HexaBPM__Parent_SR__r.HOKAR__c;

                } else{  
                    //Assign the HO Agent
                    if(stepRecord.Step_Template_Code__c == Constants.STEP_NAME_HOPRECHECK ){
                        stepRecord.OwnerID = sRRecord.HandoverDetail__r.HandoverAgent__c;
                        sRRecord.OwnerID = sRRecord.HandoverDetail__r.HandoverAgent__c;
                    }else{
                        //Assign the KAR
                        stepRecord.OwnerID = sRRecord.HOKAR__c;
                        if(sRRecord.OwnerID!=sRRecord.HOKAR__c) { sRRecord.OwnerID = sRRecord.HOKAR__c; }
                        if(sRRecord.HandoverDetail__r.OwnerId != sRRecord.HOKAR__c && sRRecord.HandoverDetail__c!=null ){hoDetails.OwnerID = sRRecord.HOKAR__c;}
                    }
                }
                update stepRecord;
                update sRRecord;
                if(sRRecord.HandoverDetail__c!=null){update hoDetails; }
            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_UpdateHOStepOwner';}
        return result;
    }
}