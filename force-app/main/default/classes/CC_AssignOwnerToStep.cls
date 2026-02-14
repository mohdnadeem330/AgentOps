global class CC_AssignOwnerToStep implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = [SELECT Id,OwnerId FROM HexaBPM__Service_Request__c WHERE Id=: stp.HexaBPM__SR__c LIMIT 1];
        if(stp!=null){
            stp.OwnerId = serviceRequest.ownerId;
            update stp;
        }
        return null;
    }
}