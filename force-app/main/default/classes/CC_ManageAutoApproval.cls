global without sharing class CC_ManageAutoApproval implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            SR = [Select id,HexaBPM__External_SR_Status__c, HexaBPM__Internal_SR_Status__c,HexaBPM__SR_Template__c from HexaBPM__Service_Request__c where id = : stp.HexaBPM__SR__c];
    
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ManageAutoApproval: Invalid SR or SR Step';
            }
            else if(stp.HexaBPM__Step_Status__c!= Constants.STATUS_APPROVED)
            {

                HexaBPM__Step__c currentstep =[Select Id,HexaBPM__Status__c,HexaBPM__Step_No__c, OwnerId, OwnerName__c,Step_Template_Code__c,HexaBPM__SR_Step__c,HexaBPM__Step_Notes__c From HexaBPM__Step__c Where HexaBPM__SR__c =: stp.HexaBPM__SR__c AND Id =: stp.Id];
                List<HexaBPM__SR_Steps__c> allsteps = [Select id,HexaBPM__Step_No__c, name, OwnerId, HexaBPM__SR_Template__c,HexaBPM__Step_Template_Code__c from HexaBPM__SR_Steps__c WHERE HexaBPM__SR_Template__c = :SR.HexaBPM__SR_Template__c AND HexaBPM__Step_Template_Code__c != :currentstep.Step_Template_Code__c AND OwnerId = :currentstep.OwnerId AND HexaBPM__Step_No__c >:currentstep.HexaBPM__Step_No__c];
                HexaBPM__Status__c approvedStatus = [Select id,name from HexaBPM__Status__c where Name =:Constants.STATUS_APPROVED];
                HexaBPM__Status__c compltedStatus = [Select id,name from HexaBPM__Status__c where Name =:Constants.COMPLETED_STATUS];
                
                // List<HexaBPM__Step__c> approvedStep = [Select Id, OwnerName__c, OwnerId,HexaBPM__SR__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c From HexaBPM__Step__c Where (HexaBPM__SR__c =: stp.HexaBPM__SR__c AND Id !=: stp.Id AND OwnerName__c =: currentstep.OwnerName__c AND (HexaBPM__Step_Status__c =:Constants.STATUS_APPROVED OR HexaBPM__Step_Status__c =:Constants.COMPLETED_STATUS))];
                
                map<String, HexaBPM__Step_Transition__c> status = new map<String,HexaBPM__Step_Transition__c>();
                for(HexaBPM__Step_Transition__c txn : [select id, HexaBPM__To__c, HexaBPM__SR_Step__c,HexaBPM__SR_Status_Internal__c,HexaBPM__SR_Status_External__c from HexaBPM__Step_Transition__c where HexaBPM__SR_Step__c = :currentstep.HexaBPM__SR_Step__c ORDER BY createdDate DESC])
                {
                    status.put(txn.HexaBPM__To__c,txn );
                }
                // System.debug('Point: approvedStep: '+ approvedStep);
                // System.debug('status:'+ status);
    
                if(!allsteps.isEmpty())
                {
                    	String nextapprovedstep = allsteps[0].HexaBPM__Step_Template_Code__c;
                        if(status.containsKey(Constants.STATUS_APPROVED))
                        {
                        currentstep.HexaBPM__Status__c = approvedStatus.id;
                        
                        if(status.get(Constants.STATUS_APPROVED).HexaBPM__SR_Status_External__c!= null)
                        SR.HexaBPM__External_SR_Status__c =  status.get(Constants.STATUS_APPROVED).HexaBPM__SR_Status_External__c;
                       
                        if(status.get(Constants.STATUS_APPROVED).HexaBPM__SR_Status_Internal__c!= null)
                        SR.HexaBPM__Internal_SR_Status__c =  status.get(Constants.STATUS_APPROVED).HexaBPM__SR_Status_Internal__c;
                        }
                        else{
                            currentstep.HexaBPM__Status__c = compltedStatus.id; 
                            if(status.get(Constants.COMPLETED_STATUS).HexaBPM__SR_Status_External__c != null)
                            SR.HexaBPM__External_SR_Status__c =  status.get(Constants.COMPLETED_STATUS).HexaBPM__SR_Status_External__c;

                            if(status.get(Constants.COMPLETED_STATUS).HexaBPM__SR_Status_Internal__c != null)
                            SR.HexaBPM__Internal_SR_Status__c =  status.get(Constants.COMPLETED_STATUS).HexaBPM__SR_Status_Internal__c;
                        }
                    currentstep.HexaBPM__Step_Notes__c = 'This step is auto approved due to step "'+ nextapprovedstep + '" Owner: ' + currentstep.OwnerName__c;
                    update SR;
                    update currentstep;  
                    
                }
                
            } 
        }
         catch(Exception e){
            //result = e.getMessage()+' :CC_ManageAutoApproval';
            LoggerService.save(LoggerService.createApexLog(e,'Exception','CC_ManageAutoApproval','CC_ManageAutoApproval'));
        }
        return result;
    }
    }