/**********************************************************************************************************************
* Name               : CC_ValidateBrokerManager                                                     
* Description        : This custom code is used to validate field validation.
* Usage              : HexaBPM Process                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
//TODO: Error Util
global without sharing class CC_ValidateBrokerManager implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result = 'Success';
        try{
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord= [select id, BrokerManager__c from HexaBPM__Service_Request__c where id = : stp.HexaBPM__SR__c  limit 1];
                if(sRRecord.BrokerManager__c == null ){
                    result='Please select broker Manager before completing the step';
                }else{
                    update new HexaBPM__Step__c(Id =stp.Id ,OwnerId=sRRecord.BrokerManager__c);
                }
            }
            
        } catch(Exception e){result = e.getMessage()+'';}
        return result;
    }
}