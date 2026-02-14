/**********************************************************************************************************************
* Name               : ProjectTeamNotificationHOBatch                                                        
* Description        : Class to Send reminder before the due date (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
//To be scheduled to run daily
global class ProjectTeamNotificationHOBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
   
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,50);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select Id,AnticipatedCompletionDate__c from BuildingSection__c   where AnticipatedCompletionDate__c  = NEXT_N_DAYS:76 and ApprovalStatus__c  in (null, \''+Constants.STATUS_DRAFT+'\',\''+Constants.APPROVED_STATUS+'\')';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<BuildingSection__c> scope){
        List<BuildingSection__c> recordToUpdate = new List<BuildingSection__c>();
        set<Integer> projectTeamNotificationDays =new set<Integer>();
        for(String tempS : System.Label.ProjectTeamNotificationFrequencyHO.split(',')){
            projectTeamNotificationDays.add(Integer.ValueOf(tempS));
        }
        set<Integer> projectTeamEscalationNotificationDays =new set<Integer>();
        for(String tempS : System.Label.ProjectTeamEscalationNotificationFrequencyHO.split(',')){
            projectTeamEscalationNotificationDays.add(Integer.ValueOf(tempS));
        }
        
        for(BuildingSection__c tempRec : scope){
            Integer daysDifference= math.abs( tempRec.AnticipatedCompletionDate__c.daysBetween(system.today()));
            if(projectTeamNotificationDays.contains(daysDifference)){
                tempRec.TriggerProjectTeamNotification__c=true;
                recordToUpdate.add(tempRec);
            }else if(projectTeamEscalationNotificationDays.contains(daysDifference)){
                tempRec.TriggerProjectTeamEscalationNotification__c =true;
                recordToUpdate.add(tempRec);
            }else if(daysDifference == Integer.ValueOf(System.Label.HO_HCLetterNotification)){
                tempRec.TriggerHCLetterReminder__c =true;
                recordToUpdate.add(tempRec);
            }else if(daysDifference == Integer.ValueOf(System.Label.HO_HandoverPhasingNotification)){
                tempRec.TriggerHPLetterReminder__c =true;
                recordToUpdate.add(tempRec);
            }
        }
        if(!recordToUpdate.isEmpty()){
            update recordToUpdate;
        }
        
    }    
    global void finish(Database.BatchableContext bc){}    
}