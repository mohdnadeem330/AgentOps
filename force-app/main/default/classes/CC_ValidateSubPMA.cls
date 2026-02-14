/**********************************************************************************************************************
* Name               : CC_ValidateSubPMA                                                        
* Description        : This class is used by Handover Process to validate
* Usage              : Handover + Title Deed Process SR PRocess
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_ValidateSubPMA implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ValidateSubPMA: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, SubPMAApplicationNumber__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                if(sRRecord.SubPMAApplicationNumber__c==null || sRRecord.SubPMAApplicationNumber__c=='' ){
                    result='Please add Sub PMA Application Number' ;
                }
            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_ValidateSubPMA';
        }
        return result;
    }
}