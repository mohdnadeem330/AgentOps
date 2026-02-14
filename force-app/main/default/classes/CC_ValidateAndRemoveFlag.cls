/**********************************************************************************************************************
* Name               : CC_ValidateAndRemoveFlag                                                   
* Description        : This custom code is used to remove the flag from the Account as sson as Child SR is closed
* Usage              : HexaBPM Process                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
//TODO: Error Util
global without sharing class CC_ValidateAndRemoveFlag implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result = 'Success';
        try{
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord= [select id, HexaBPM__Parent_SR__c, HexaBPM__Parent_SR__r.RecordTypeId from HexaBPM__Service_Request__c where id = : stp.HexaBPM__SR__c  limit 1];
                HexaBPM__Step__c stepRecord = [select id,HexaBPM__Step_Status__c,Step_Template_Code__c from HexaBPM__Step__c where id = :stp.Id limit 1];
                Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);
                
                if(sRRecord.HexaBPM__Parent_SR__c!=null && sRRecord.HexaBPM__Parent_SR__r.RecordTypeId == DandTRecordTypeId ){
                    String flagType = stepRecord.Step_Template_Code__c == Constants.STEP_NAME_COURT_FILING ? 'Legal':'Default';
                    DefaultAndTerminationUtility.checkAndAutoUnflag(new set<ID>{sRRecord.HexaBPM__Parent_SR__c},flagType);
                }
            }
            
        } catch(Exception e){result = e.getMessage()+'';}
        return result;
    }
}