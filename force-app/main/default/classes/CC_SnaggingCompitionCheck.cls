global without sharing class CC_SnaggingCompitionCheck implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
         HexaBPM__Service_Request__c sRRecord = [SELECT Id,HandoverDetail__r.QASnaggingDate__c,HandoverDetail__r.QADesnaggingDate__c 
                                                        FROM HexaBPM__Service_Request__c
                                                         WHERE Id =: stp.HexaBPM__SR__c  Limit 1];
        
       
         
        if(stp.HexaBPM__Summary__c==Constants.QA_SNAGGING_STEP) {
           if(sRRecord.HandoverDetail__r.QASnaggingDate__c==null){
                 return Utilities.getSystemMessages(Constants.QA_SNAGGING_DATE_CHECK).Message__c;
             }        
        }
        
        if(stp.HexaBPM__Summary__c==Constants.QA_DESNAGGING_STEP){
            if(sRRecord.HandoverDetail__r.QADesnaggingDate__c==null){
                return Utilities.getSystemMessages(Constants.QA_DE_SNAGGING_DATE_CHECK).Message__c;
             } 
         }
        
      return null;
    }
}