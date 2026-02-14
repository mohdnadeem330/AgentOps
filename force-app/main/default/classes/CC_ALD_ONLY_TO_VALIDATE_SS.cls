global without sharing class CC_ALD_ONLY_TO_VALIDATE_SS implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        System.debug('### Invoked');
        string result ='CC_ALD_ONLY_TO_VALIDATE_SS';
        
        return result;
    }
}