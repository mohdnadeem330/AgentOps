global without sharing class CC_ManageStepOwner implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ManageStepOwner: Invalid SR or SR Step';
            }else{

                List<HexaBPM__Step__c> allStepsRelatedToSR = [Select Id, QueueId__c, QueueName__c,OwnerId, Owner.name, Owner.IsActive From HexaBPM__Step__c Where HexaBPM__SR__c =: stp.HexaBPM__SR__c AND Id !=: stp.Id AND QueueId__c != null];
                Map<Id,Id> queueIdWithUserId = new Map<Id,Id>();

                System.debug('Point: allStepsRelatedToSR: '+ allStepsRelatedToSR);
                for(HexaBPM__Step__c step : allStepsRelatedToSR){
                    if(step.Owner.IsActive){
                        queueIdWithUserId.put(step.QueueId__c, step.OwnerId);
                    }
                }

                System.debug('Point: queueIdWithUserId: '+ queueIdWithUserId);

                if(queueIdWithUserId.containsKey(stp.OwnerId)){
                    stp.OwnerId = queueIdWithUserId.get(stp.OwnerId);
                    update stp;
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_ManageStepOwner';
        }
        return result;
    }
}