/**********************************************************************************************************************
* Name               : RoundRobinAssignmentUtility                                                        
* Description        : This class is used as to provide all helper methods for round Robin Assignment
* Usage              : opportunityUnitSearch LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class RoundRobinAssignmentUtility {
    public static boolean roundRobinAssignmentFlow =false;
    /* 
    * Method will mark all the users as available
    */
    public static void setAgentAvailable(set<id> userIds){
        list<RoundRobinAssignmentMatrix__c> agentRecords = [select id,status__c from RoundRobinAssignmentMatrix__c where User__c in : userIds WITH SECURITY_ENFORCED];
        for(RoundRobinAssignmentMatrix__c tempRecord : agentRecords){
            tempRecord.status__c=Constants.STATUS_AVAILABLE;
        }
        if(!agentRecords.isEmpty()){
            update agentRecords;
        }
    }
    /* 
    * Method will mark all the users as offline
    */
    public static void setAgentOffline(set<id> userIds){
        list<RoundRobinAssignmentMatrix__c> agentRecords = [select id,status__c from RoundRobinAssignmentMatrix__c where User__c in : userIds WITH SECURITY_ENFORCED];
        for(RoundRobinAssignmentMatrix__c tempRecord : agentRecords){
            tempRecord.status__c=Constants.STATUS_OFFLINE;
        }
        if(!agentRecords.isEmpty()){
            update agentRecords;
        }
    }
    /* 
    *   Method to check the agent availabilty
    */
    public static map<Id,boolean> getAgentAvailibility(set<id> userIds){
        map<Id,boolean> statusMapToReturn = new map<Id,boolean>();
        //get map of users sorted by LastAssignmentTime__c asc, createdDate asc
        for(RoundRobinAssignmentMatrix__c tempAssignmentRecord : [select User__c,status__c,AgentThreshold__c,CurrentLoad__c from RoundRobinAssignmentMatrix__c where User__c in : userIds WITH SECURITY_ENFORCED ]){
            statusMapToReturn.put(tempAssignmentRecord.User__c, (/*tempAssignmentRecord.CurrentLoad__c < tempAssignmentRecord.AgentThreshold__c && */tempAssignmentRecord.status__c!=null && tempAssignmentRecord.status__c.equalsIgnoreCase(Constants.STATUS_AVAILABLE))  );
        }
        return statusMapToReturn;
    }
    /* 
    *   Method to check the agent availabilty
    */
    public static map<Id,Integer> getAvailibleAgentWorkCapacity(set<id> userIds){
        map<Id,Integer> statusMapToReturn = new map<Id,Integer>();
        //get map of users sorted by LastAssignmentTime__c asc, createdDate asc
        for(RoundRobinAssignmentMatrix__c tempAssignmentRecord : [select User__c,status__c,AgentThreshold__c,CurrentLoad__c from RoundRobinAssignmentMatrix__c where User__c in : userIds and status__c = :Constants.STATUS_AVAILABLE  WITH SECURITY_ENFORCED ]){
            statusMapToReturn.put(tempAssignmentRecord.User__c,  Integer.valueOf(tempAssignmentRecord.AgentThreshold__c - tempAssignmentRecord.CurrentLoad__c ));
        }
        return statusMapToReturn;
    }
    /* 
    * Method will return lead to agent map 
    *  (DML on RoundRobinAssignmentMatrix__c update current LoadCount+ LastAssignmentTime)
    */
    public static map<Id,Id> getAvailableAgent(set<id> leadIds){
        map<Id,Id> leadToOwnerMap = new map<Id,Id>();
        map<id,RoundRobinAssignmentMatrix__c> userToAssignmentRecord = new map<id,RoundRobinAssignmentMatrix__c>();
        //get map of users sorted by LastAssignmentTime__c asc, createdDate asc
        //Lead_Type__c Added by Arvind
         List<RoundRobinAssignmentMatrix__c> rrList = new List<RoundRobinAssignmentMatrix__c>();
        if(test.isRunningTest()){
            rrList = [select id,LastAssignmentTime__c,Property__c,User__c,status__c,AgentThreshold__c,LeadType__c,Lead_Type__c,CurrentLoad__c,SalesType__c,PropertyUsage__c,BuyRent__c,SalesOrigin__c,LeadOrigin__c,CustomerLocation__c,EnquiryTrigger__c,EnquiryCategory__c,Offer__c,Language__c,MethodofContact__c,AudienceSegmentation__c
                      from RoundRobinAssignmentMatrix__c where User__r.isActive=true and status__c= :Constants.STATUS_AVAILABLE order by LastAssignmentTime__c asc, createdDate asc ];
        }else{
            rrList = [select id,LastAssignmentTime__c,Property__c,User__c,status__c,AgentThreshold__c,LeadType__c,Lead_Type__c,CurrentLoad__c,SalesType__c,PropertyUsage__c,BuyRent__c,SalesOrigin__c,LeadOrigin__c,CustomerLocation__c,EnquiryTrigger__c,EnquiryCategory__c,Offer__c,Language__c,MethodofContact__c,AudienceSegmentation__c
                      from RoundRobinAssignmentMatrix__c where User__r.isActive=true and status__c= :Constants.STATUS_AVAILABLE WITH SECURITY_ENFORCED order by LastAssignmentTime__c asc, createdDate asc ];
        }
          for(RoundRobinAssignmentMatrix__c tempAssignmentRecord : rrList){
            //if(tempAssignmentRecord.CurrentLoad__c < tempAssignmentRecord.AgentThreshold__c){
                userToAssignmentRecord.put(tempAssignmentRecord.User__c,tempAssignmentRecord);
            //}
        }
        system.debug('userToAssignmentRecord:::'+userToAssignmentRecord);
        //get and update the latest counter
        updateRRLoadCounter(userToAssignmentRecord);
        
        map<id,integer> totalLoacalAssigenments = new map<id,integer>();
        //For every lead
        //Lead_Type__c
        for(Lead tempLeadRec : [select id,Lead_Type__c,Project__c,OwnerId,SalesType__c,PropertyUsage__c,BuyRent__c,SalesOrigin__c,LeadOrigin__c,CustomerLocation__c,EnquiryTrigger__c,EnquiryCategory__c,Offer1__c,LanguagePreference__c,LeadSource,CustomerSubType__c
                                from lead where id in :leadIds WITH SECURITY_ENFORCED]){
                                    system.debug('tempLeadRec::'+tempLeadRec);
           //Customer location behaves other than Emirates city
           //Lead_Type__c- Added by ARvind for Resale
           if (tempLeadRec.CustomerLocation__c == null || (tempLeadRec.CustomerLocation__c != 'Abu Dhabi' && tempLeadRec.CustomerLocation__c != 'Ajman' && tempLeadRec.CustomerLocation__c != 'Dubai'&& tempLeadRec.CustomerLocation__c != 'Fujairah' && tempLeadRec.CustomerLocation__c != 'Ras al-Khaimah'&& tempLeadRec.CustomerLocation__c != 'Sharjah'&& tempLeadRec.CustomerLocation__c != 'Umm al-Quwain'&& tempLeadRec.CustomerLocation__c != 'Al Ain'))
			{
				
				tempLeadRec.CustomerLocation__c = 'Others';
			}
                                    
              if (tempLeadRec.Lead_Type__c == null)
            {	
				tempLeadRec.Lead_Type__c = 'New Sale';
			}
			
                
            Integer userPoint = -1;
            set<ID> possibleUserSet = new set<ID>();
            for(Id tempUserId : userToAssignmentRecord.keySet() ){
                 system.debug('tempUserId::'+tempUserId);
                Integer tempUserPoints = 0;
                RoundRobinAssignmentMatrix__c tempAssignmentRecord = userToAssignmentRecord.get(tempUserId);
                system.debug('tempAssignmentRecord::'+tempAssignmentRecord);
                //Assign only if agent have capacity and Agent is not previous owner
                if(tempAssignmentRecord.CurrentLoad__c < tempAssignmentRecord.AgentThreshold__c && tempLeadRec.OwnerId!=tempAssignmentRecord.User__c){
                    //Check Matching Field calculate pointers
                    //If field is blank that means agent is able to handle all the requests
                    
                      //Added by Arvind for Resale
                      //Chnaged the LeadType__c as multiselected field
                    if(tempAssignmentRecord.LeadType__c ==null || (tempLeadRec.Lead_Type__c!=null && tempAssignmentRecord.LeadType__c.contains(tempLeadRec.Lead_Type__c) )){
                        tempUserPoints++;
                    }
                    
                    if(tempAssignmentRecord.SalesType__c==null || (tempLeadRec.SalesType__c!=null && tempAssignmentRecord.SalesType__c.contains(tempLeadRec.SalesType__c) )){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.PropertyUsage__c==null || ( tempLeadRec.PropertyUsage__c!=null && tempAssignmentRecord.PropertyUsage__c.contains(tempLeadRec.PropertyUsage__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.BuyRent__c==null || ( tempLeadRec.BuyRent__c!=null && tempAssignmentRecord.BuyRent__c.contains(tempLeadRec.BuyRent__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.Property__c==null || ( tempLeadRec.Project__c!=null && tempAssignmentRecord.Property__c.contains(tempLeadRec.Project__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.Offer__c==null || ( tempLeadRec.Offer1__c!=null && tempAssignmentRecord.Offer__c.contains(tempLeadRec.Offer1__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.Language__c==null || ( tempLeadRec.LanguagePreference__c!=null && tempAssignmentRecord.Language__c.contains(tempLeadRec.LanguagePreference__c) ) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.SalesOrigin__c==null || ( tempLeadRec.SalesOrigin__c!=null && tempAssignmentRecord.SalesOrigin__c.contains(tempLeadRec.SalesOrigin__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.LeadOrigin__c==null || ( tempLeadRec.LeadOrigin__c!=null && tempAssignmentRecord.LeadOrigin__c.contains(tempLeadRec.LeadOrigin__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.CustomerLocation__c==null || ( tempLeadRec.CustomerLocation__c!=null && tempAssignmentRecord.CustomerLocation__c.contains(tempLeadRec.CustomerLocation__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.MethodofContact__c==null || ( tempLeadRec.LeadSource!=null && tempAssignmentRecord.MethodofContact__c.contains(tempLeadRec.LeadSource)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.EnquiryTrigger__c==null || ( tempLeadRec.EnquiryTrigger__c!=null && tempAssignmentRecord.EnquiryTrigger__c.contains(tempLeadRec.EnquiryTrigger__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.EnquiryCategory__c==null || ( tempLeadRec.EnquiryCategory__c!=null && tempAssignmentRecord.EnquiryCategory__c.contains(tempLeadRec.EnquiryCategory__c)) ){
                        tempUserPoints++;
                    }
                    if(tempAssignmentRecord.AudienceSegmentation__c==null || ( tempLeadRec.CustomerSubType__c!=null && tempAssignmentRecord.AudienceSegmentation__c.contains(tempLeadRec.CustomerSubType__c) )){
                        tempUserPoints++;
                    }
                    // Assign only if all the attributes are satisfied
                    If(tempUserPoints < Integer.valueOf( System.Label.RRParameterCount ) ){
                        continue;
                    }
                    system.debug('tempUserPoints::'+tempUserPoints);
                     system.debug('userPoint::'+userPoint);
                    //If higherpointer add create new list
                    if(userPoint < tempUserPoints ){
                        userPoint = tempUserPoints;
                        possibleUserSet = new set<ID>{ tempAssignmentRecord.User__c };
                    }else if(userPoint == tempUserPoints){
                        //If same then keep add to list
                        possibleUserSet.add(tempAssignmentRecord.User__c);
                    }
                  
                }
            }
           system.debug('possibleUserSet::'+possibleUserSet);
            if(!possibleUserSet.isEmpty()){
                ID userId = null;
                //Dummy val for getting agent with lower amount of work
                integer currentWork = 1000;
                for(Id tempUserId : possibleUserSet){
                    if(!totalLoacalAssigenments.containskey(tempUserId)){
                        totalLoacalAssigenments.put(tempUserId,0);
                        userId = tempUserId;
                        break;
                    }else{
                        if( currentWork > totalLoacalAssigenments.get(tempUserId)){
                            userId = tempUserId;
                            currentWork=totalLoacalAssigenments.get(tempUserId);
                        }
                    }
                }
                system.debug('userId::'+userId);
                //Once finalized update the CurrentLoad__c and totalLoacalAssigenments to continue RR
                totalLoacalAssigenments.put(userId,totalLoacalAssigenments.get(userId) + 1);
                userToAssignmentRecord.get(userId).CurrentLoad__c = userToAssignmentRecord.get(userId).CurrentLoad__c + 1;
                userToAssignmentRecord.get(userId).LastAssignmentTime__c = system.now();
                leadToOwnerMap.put(tempLeadRec.Id,userId);
            }
        }
        system.debug('totalLoacalAssigenments::'+totalLoacalAssigenments);
        system.debug('leadToOwnerMap::'+leadToOwnerMap);
        system.debug('userToAssignmentRecord::'+userToAssignmentRecord);
        //update the last assignment time
        if(!leadToOwnerMap.isEmpty()){  
            update userToAssignmentRecord.values();
        }
        return leadToOwnerMap;
    }
    /*
    * Method to initialize/return the lead record with RR agent assignment
    * Calling method must update the Lead records if required
    * (DML on RoundRobinAssignmentMatrix__c update current LoadCount+ LastAssignmentTime
    * DML create day1Task1)
    */
    public static map<id,Lead> getAgentAssignment(map<id,Lead> leadMap){
        integer defaultSLA = Integer.ValueOf(System.label.ROUNDROBIN_SM_SLA );
        map<id,id> leadToOwnerMap = getAvailableAgent(leadMap.keySet());
        List<Group> defaultQueue = [select id,name,developerName from group where type='Queue' and developerName=:Constants.DEFAULT_RR_QUEUE];
        DateTime actionSLATime = getActionSLA(defaultSLA);
        for(ID leadId : leadMap.keySet()){
            if(leadToOwnerMap.containsKey(leadId)){
                leadMap.get(leadId).ownerId= leadToOwnerMap.get(leadId);
                leadMap.get(leadId).AssignmentSLATime__c =ActionSLATime;
                leadMap.get(leadId).AssignedTimetoSM__c =system.now();
            }else{
                leadMap.get(leadId).AssignmentSLATime__c = system.now();
                if(!defaultQueue.isEmpty()){
                    leadMap.get(leadId).ownerId = defaultQueue[0].id;
                     leadMap.get(leadId).AssignedTimetoSM__c =system.now();
                }
            }
        }
        //create Tasks
        //createDay1Task1(leadToOwnerMap, defaultSLA);
        roundRobinAssignmentFlow=true;
        return leadMap;
    }
    public static dateTime getActionSLA(integer sla){
        Integer SLAinHours = sla; //Integer.ValueOf(System.label.ROUNDROBIN_SM_SLA );// Constants.AGENT_ACTION_SLA_TIME_IN_HOURS;
        list<BusinessHours> orgBusinessHours = [select Id from BusinessHours where IsActive = true and IsDefault=true];
        DateTime actionSLATime = system.now();
        if(orgBusinessHours.isEmpty()){
            actionSLATime = actionSLATime.addHours(SLAinHours);
        }else{
            Long interval = SLAinHours*60*60*1000;
            actionSLATime = BusinessHours.add(orgBusinessHours[0].id , system.now() , interval  );
        }
        return actionSLATime;
    }
    /*
    * updateRRLoadCounter this method will count the current load for the given owners and update it
    */
    public static void updateRRLoadCounter(map<id,RoundRobinAssignmentMatrix__c> RRRecords){
        for(RoundRobinAssignmentMatrix__c tempAssignmentRecord : RRRecords.values()){
            tempAssignmentRecord.CurrentLoad__c=0;
        }
        for(Lead tempLeadRecord : [select id,OwnerId from Lead where ownerId in : RRRecords.KeySet() and status = :Constants.QUALIFIED WITH SECURITY_ENFORCED ]){
            RRRecords.get(tempLeadRecord.ownerID).CurrentLoad__c++;
        }
    }

    /*
    * Once task is closed, the Assignment should be removed
    */
    public static void removeReassignmentCounter(set<id> leadIDs){
        list<Lead> leadRecords = new list<Lead>();
        for(Id leadId : leadIDs){
            leadRecords.add(new Lead(id=leadId , AssignmentSLATime__c=null));
        }
        if(!leadRecords.isEmpty()){
            update leadRecords;
        }
    }

    /*
    * Create Day 1 Task 1 for SM
    
    public static void createDay1Task1(map<id,id> leadToOwnerMap, integer SLAinHours){
        list<Task> taskToInsert = new list<Task>();
        DateTime actionSLATime = getActionSLA(SLAinHours);
        
        system.debug('Point: leadToOwnerMap '+leadToOwnerMap);

        for(Id leadId : leadToOwnerMap.keySet()){
            //TODO: move to utility subject
            system.debug('Point: leadId '+leadId);
            taskToInsert.add(new Task(Subject=Constants.TASK_DAY1,
                                      WhoId=leadId,
                                      TaskNumber__c = 9,
                                      ReminderDateTime= actionSLATime, 
                                      IsReminderSet=true,
                                      ActivityDate=date.newinstance(actionSLATime.year(), actionSLATime.month(), actionSLATime.day()),
                                      OwnerId=leadToOwnerMap.get(leadId) ));
            //Use default Status, Priority
        }
        if(!taskToInsert.isEmpty()){
            insert taskToInsert;
        }
    
    }*/

}