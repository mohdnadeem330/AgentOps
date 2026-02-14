/**********************************************************************************************************************
* Name               : ProjectTeamNotificationDTBatch                                                        
* Description        : Class to Send reminder before the due date (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
//To be scheduled to run daily
global class ProjectTeamNotificationDTBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
   
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,50);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select Id,InstallmentDate__c from PaymentInstallments__c where InstallmentDate__c = NEXT_N_DAYS:66 and ApprovalStatus__c in (null, \''+Constants.STATUS_DRAFT+'\')';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<PaymentInstallments__c> scope){
        List<PaymentInstallments__c> recordToUpdate = new List<PaymentInstallments__c>();
        set<Integer> projectTeamNotificationDays =new set<Integer>();
        
        for(String tempS : System.Label.ProjectTeamNotificationFrequencyDT.split(',')){
            projectTeamNotificationDays.add(Integer.ValueOf(tempS));
        }
        
        set<Integer> projectTeamEscalationNotificationDays =new set<Integer>();
        for(String tempS : System.Label.ProjectTeamEscalationNotificationFrequencyDT.split(',')){
            projectTeamEscalationNotificationDays.add(Integer.ValueOf(tempS));
        }
        
        for(PaymentInstallments__c tempRec : scope){
            Integer daysDifference= math.abs( tempRec.InstallmentDate__c.daysBetween(system.today()));
            system.debug(daysDifference);
            
            if(projectTeamNotificationDays.contains(daysDifference)){
                tempRec.TriggerProjectTeamNotification__c=true;
                recordToUpdate.add(tempRec);
            }else if(projectTeamEscalationNotificationDays.contains(daysDifference)){
                tempRec.TriggerProjectTeamEscalationNotification__c =true;
                recordToUpdate.add(tempRec);
            }
        }
        if(!recordToUpdate.isEmpty()){
            update recordToUpdate;
        }
        
    }    
    global void finish(Database.BatchableContext bc){}    
}