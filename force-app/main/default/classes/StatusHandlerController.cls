/**********************************************************************************************************************
* Name               : StatusHandlerController                                                        
* Description        : This class is used as controller for LWC (StatusHandler)
* Usage              : StatusHandler LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 APR 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class StatusHandlerController{
    
    /**
    * getRRAssignmentRecord 
    *
    * return RoundRobinAssignmentMatrix__c records for logged in User
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param none
    * @return    list<RoundRobinAssignmentMatrix__c>  RoundRobinAssignmentMatrix__c records for logged in User
    * 
    */
    @auraEnabled
    public static list<RoundRobinAssignmentMatrix__c> getRRAssignmentRecord(){
        return[select id, Status__c, User__c,User__r.Name,StatusBoolean__c, LastAssignmentTime__c, CurrentLoad__c, AgentThreshold__c from RoundRobinAssignmentMatrix__c where User__c = :userInfo.getUserId()];
    }

     /**
    * getRRAssignmentTeamRecord 
    *
    * return RoundRobinAssignmentMatrix__c records for User where the logged in user is manager
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param none
    * @return    list<RoundRobinAssignmentMatrix__c>  RoundRobinAssignmentMatrix__c records
    * 
    */
    @auraEnabled
    public static list<RoundRobinAssignmentMatrix__c> getRRAssignmentTeamRecord(){
        map<id,User> myTeamUsers = new map<id,User>([select id from User where ManagerID = :userInfo.getUserId()]);
        return[select id, Status__c,User__c,User__r.Name,StatusBoolean__c, LastAssignmentTime__c, CurrentLoad__c, AgentThreshold__c from RoundRobinAssignmentMatrix__c where User__c = :myTeamUsers.keySet()];
    }
    
    /**
    * updateStatus 
    *
    * uopdate the agent status to available/offline
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param userID Record ID
    * @param isAgentAvaibale Record IDtrue means agent is available
    * @return    none
    * 
    */
    @auraEnabled
    public static void updateStatus(ID userID,boolean isAgentAvaibale){
        if(isAgentAvaibale){
            RoundRobinAssignmentUtility.setAgentAvailable(new set<ID>{userID});
        }else{
            RoundRobinAssignmentUtility.setAgentOffline(new set<ID>{userID});
        }
    }
}