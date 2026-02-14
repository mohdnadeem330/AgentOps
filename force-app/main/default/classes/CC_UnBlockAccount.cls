global without sharing class CC_UnBlockAccount implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result = 'Success';
        try{
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord= [select id, LegalFees__c, HexaBPM__Customer__c from HexaBPM__Service_Request__c where id = : stp.HexaBPM__SR__c  limit 1];
                update new Account(Id= sRRecord.HexaBPM__Customer__c , Blacklisted__c =false , BlacklistReason__c=null);
            }
            
        } catch(Exception e){result = e.getMessage()+'';}
        return result;
    }
}