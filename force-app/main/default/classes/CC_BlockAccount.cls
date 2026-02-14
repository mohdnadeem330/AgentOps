/**********************************************************************************************************************
* Name               : CC_BlockAccount                                                     
* Description        : This custom code is used to block the account once the step is transferred to legal
* Usage              : HexaBPM Process                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
//TODO: Error Util
global without sharing class CC_BlockAccount implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result = 'Success';
        try{
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord= [select id, LegalFees__c, HexaBPM__Customer__c from HexaBPM__Service_Request__c where id = : stp.HexaBPM__SR__c  limit 1];
                update new Account(Id= sRRecord.HexaBPM__Customer__c , Blacklisted__c =true , BlacklistReason__c='Legal');
            }
            
        } catch(Exception e){result = e.getMessage()+'';}
        return result;
    }
}