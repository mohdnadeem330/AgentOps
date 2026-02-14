public class ECSS_RoundRobinQueueable implements Queueable {
    String objectName {get;set;}
    List<String> Ids {get;set;}
    List<Assignment_Engine__c> EngList {get;set;}
    List<String> compIds {get;set;}
    List<String> combinedCompIds {get;set;}
    Boolean checkManager {get;set;}
    
    public ECSS_RoundRobinQueueable(String objectName, List<String> Ids, List<Assignment_Engine__c> EngList,List<String> compIds, List<String> combinedCompIds, Boolean checkManager){
        this.objectName = objectName;
        this.Ids = Ids;
        this.EngList = EngList;
        this.compIds = compIds;
        this.combinedCompIds = combinedCompIds;
        this.checkManager = checkManager;
    }
    public void execute(QueueableContext context) {
        // Get the current Engine Id and Criteria
        String EngineId = (this.EngList[0]).Id;
        Boolean noCriteriaEngine = (this.EngList[0]).No_Criteria__c;
        String criteria = (this.EngList[0]).criteria__c;
        String compId = '';
        if(this.compIds != null && this.compIds.size()>0){
            compId = this.compIds[0];
            System.debug('compId entered: '+compId);
        }
        System.debug('CompId: '+ compId);
        System.debug('Initial this.combinedCompIds: '+this.combinedCompIds);
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Assignment_Notifications'];
        // Get the current user's ID
        String currentUserId = UserInfo.getUserId();
        
        // Query the User object
        User currentUser = [SELECT Id, Name, Email, Profile.Name, ManagerId , ECSS_SalesAgent__c,RoleName__c
                            FROM User 
                            WHERE Id = :currentUserId];
        String currentManagerId = '';
        Set<Id> MangedUserIds = new Set<Id>();
        if(currentUser.RoleName__c == 'Leasing Manager/Team Lead'){
            currentManagerId = currentUserId;
            //query and get all the related team for the manager
            List<User> relatedTeam = [SELECT Id,ManagerId from User where ManagerId =: currentManagerId];
            Map<Id, User> usersMap = new Map<Id, User>(relatedTeam);
            MangedUserIds = usersMap.keySet();
            System.debug('userIds : '+ MangedUserIds);
            System.debug('curentUsrId:'+currentUserId);
        }
        
        Messaging.CustomNotification notify = new Messaging.CustomNotification();
        List<Round_Robin_User__c> RRUList = new List<Round_Robin_User__c> ();
        if(this.compIds != null && this.compIds.size()>0){
            //Get the round robin users assigned to the criteria (disregarding the company)
            RRUList = [select id,Counter__c ,Assigned_User__c,Available__c,Assigned_User__r.ManagerId,
                       (select id, Assignment_Engine__c from Round_Robin_Engine_Assignments__r where Assignment_Engine__c =:EngineId)
                       from Round_Robin_User__c WHERE id in (SELECT Round_robin_user__c from Round_Robin_Engine_Assignment__c where Assignment_Engine__c =:EngineId) AND Available__c = true];
        }
        else{
            //Get the round robin users assigned to the criteria (taking into consideration the company)
            RRUList = [select id,Counter__c ,Assigned_User__c,Available__c,Assigned_User__r.ManagerId,
                       (select id, Assignment_Engine__c, Company__c from Round_Robin_Engine_Assignments__r where Assignment_Engine__c =:EngineId and Company__c =: compId)
                       from Round_Robin_User__c WHERE id in (SELECT Round_robin_user__c from Round_Robin_Engine_Assignment__c where Assignment_Engine__c =:EngineId and Company__c =: compId) AND Available__c = true];
        }
        
        
        //Get the leads that follow the current Engine's criteria
        String idsString = '(\'' + String.join(this.Ids, '\', \'') + '\')';
        String query = '';
        System.debug('53 ' + this.objectName);
        if(this.objectName == 'Lead')
            query = 'SELECT Id,OwnerId,Name,ECSS_Owner_Manager__c  FROM '+ this.objectName;
        if(this.objectName == 'Case')
            query = 'SELECT Id,OwnerId,CaseNumber FROM '+ this.objectName;
        if(this.objectName == 'Opportunity')
            query = 'SELECT Id,OwnerId,StageName,Name FROM '+ this.objectName;
        query += ' WHERE Id in '+idsString;
        if(!noCriteriaEngine)
            query += ' AND '+criteria;
        if(compId != null && compId != ''){
            query += ' AND ECSS_Company__c = '+ '\''+compId +'\'';
        }
        System.debug('QUERY:'+query);
        List<sObject> objectList = Database.query( query );
        
        List<String> userIds = new List<String>();
        Map<String,String> userToManagerMap = new Map<String,String>();
        
        System.debug('Query: '+objectList);
        System.debug('RRUList: '+RRUList);
        
        List<UserSortWrapper> userSortWrappers = new List<UserSortWrapper>();
        for (Round_Robin_User__c user : RRUList) {
            userSortWrappers.add(new UserSortWrapper(user));
            userIds.add(user.Assigned_User__c);
        }
        userSortWrappers.sort();
        List<Round_Robin_User__c> roundRobinsSorted = new List<Round_Robin_User__c>();
        for (UserSortWrapper wrapper : userSortWrappers) {
            roundRobinsSorted.add(wrapper.usrRoundRobin);
        }
        
        
        //Create a map to know the users' managers in the current company
        Id recordTypeId = Schema.SObjectType.Round_Robin_User__c.getRecordTypeInfosByName()
            .get('CompanyRole')
            .getRecordTypeId();
        System.debug('UserIds + '+userIds);
        System.debug('CompId + '+compId);
        System.debug('recordTypeId + '+recordTypeId);
        List<Round_Robin_User__c> compRoleList = [SELECT Id,Assigned_User__c,Assigned_Manager__c FROM Round_Robin_User__c WHERE Assigned_User__c in: userIds AND Company__c=: compId and recordTypeId =: recordTypeId];
        System.debug('compRoleList: '+compRoleList);    
        // Iterate through the list and populate the map
        for (Round_Robin_User__c record : compRoleList) {
            userToManagerMap.put(record.Assigned_User__c, record.Assigned_Manager__c);
        }
        System.debug('userToManagerMap: '+userToManagerMap);
        System.debug('InitalcompBefore: '+this.combinedCompIds);
        List<String> currCombinedCompIds = this.combinedCompIds;
        if(this.compIds != null && this.compIds.size()>0)
            this.compIds.remove(0); 
        
        System.debug('COMP After Removal => '+this.compIds);
        System.debug('InitalcompAfter: '+this.combinedCompIds);
        System.debug('ObjectList '+objectList);
        System.debug('RoundRobinSorted '+roundRobinsSorted);
        System.debug('CheckManager '+this.checkManager);
        for(sObject currRecord :objectList){
            Set<String> recpientIds = new Set<String>();
            if(!roundRobinsSorted.isEmpty()){
                userSortWrappers.sort();
                if(this.checkManager){
                    //The new owner should belong to the same team (have the same manager)
                    //  String currManagerId = (String)currRecord.get('ECSS_Owner_Manager__c');
                    String currManagerId = '';
                    if(currentUser.ManagerId != null)
                     currManagerId = currentUser.ManagerId;
                    System.debug('currManagerId: '+ currManagerId);
                    String OldOwner = (String)currRecord.get('OwnerId'); 
                    roundRobinsSorted = new List<Round_Robin_User__c>();
                    for (UserSortWrapper wrapper : userSortWrappers) {
                        System.debug('wrapper.usrRoundRobin:'+wrapper.usrRoundRobin);
                        System.debug('currUserId:'+(wrapper.usrRoundRobin).Assigned_User__c);
                        String currUserId = (wrapper.usrRoundRobin).Assigned_User__c;
                        String ManagerId = userToManagerMap.get(currUserId);
                        System.debug('ManagerId: '+ManagerId);
                        if(currentManagerId != '' && currentManagerId != null && currUserId != OldOwner){
                            System.debug('entered in the currmanager');
                            //this means that the manager created the lead, so time to assign to the corresponding team
                            if(MangedUserIds.contains(currUserId)){
                                System.debug('ManagerUserIds contained:');
                                roundRobinsSorted.add(wrapper.usrRoundRobin);
                            }
                        }
                        else if(currManagerId == ManagerId  && currUserId != OldOwner ){
                            System.debug('Entered here');
                            roundRobinsSorted.add(wrapper.usrRoundRobin);
                        }
                        
                    }
                }
                else{
                    for (UserSortWrapper wrapper : userSortWrappers) {
                        roundRobinsSorted.add(wrapper.usrRoundRobin);
                    }
                }
                if(!roundRobinsSorted.isEmpty()){
                    System.debug('Sorted Related Users: '+roundRobinsSorted);
                    System.debug('AssignedUser:'+ roundRobinsSorted[0]+ ', On Record: '+ currRecord);
                    String assignedUserId = (roundRobinsSorted.get(0)).Id;  
                    String userId = (roundRobinsSorted.get(0)).Assigned_User__c;
                    String managerId = userToManagerMap.get(userId);
                    
                    //Add the fields to be put for each object type
                    if(this.objectName == 'Lead'){
                        System.debug('In the if condition');
                        currRecord.put('OwnerId',userId);
                        currRecord.put('ECSS_Assigned__c',true);
                        currRecord.put('ECSS_Owner_Manager__c',managerId);
                        currRecord.put('Status','Assigned');
                        currRecord.put('ECSS_Escalation_Level__c',0);
                        currRecord.put('ECSS_Assigned_Date_Time__c', System.now());
                        currRecord.put('ECSS_SLA_Date__c', System.now());
                        currRecord.put('ECSS_SLA_Entry__c', true);
                        currRecord.put('ECSS_Re_Assign__c', false);
                        System.debug('currRecord:'+currRecord);
                        System.debug('OwnerId: '+userId);
                        recpientIds.add(userId);
                        notify.settitle('Lead Assignment');
                        notify.setbody('You have been assigned to the following lead: '+  (String)currRecord.get('Name'));
                        notify.setnotificationtypeid(notificationType.Id);
                        notify.settargetid( (String)currRecord.get('Id'));    
                        notify.send(recpientIds);
                    }
                    
                    if(this.objectName == 'Case'){
                        currRecord.put('OwnerId',userId);
                        currRecord.put('ECSS_Assigned_Date_Time__c', System.now());
                        recpientIds.add(userId);
                        notify.settitle('Case Assignment');
                        notify.setbody('You have been assigned to the following Case: '+  (String)currRecord.get('CaseNumber'));
                        notify.setnotificationtypeid(notificationType.Id);
                        notify.settargetid( (String)currRecord.get('Id'));    
                        notify.send(recpientIds);
                    }
                    
                    System.debug('171 ');
                    if(this.objectName == 'Opportunity'){
                        System.debug('172 ' + userId);
                        currRecord.put('OwnerId',userId);
                        currRecord.put('ECSS_Assigned_Date_Time__c', System.now());
                        currRecord.put('StageName', 'New');
                        recpientIds.add(userId);
                        notify.settitle('Opportunity Assignment');
                        notify.setbody('You have been assigned to the following Opportunity: '+  (String)currRecord.get('Name'));
                        notify.setnotificationtypeid(notificationType.Id);
                        System.debug('182 ' + notificationType.Id);
                        notify.settargetid( (String)currRecord.get('Id'));    
                        System.debug('184 ' +(String)currRecord.get('Id'));
                        notify.send(recpientIds);
                    }
                    
                    //Update round robin user's count
                    roundRobinsSorted.get(0).Counter__c += 1;
                    System.debug('roundRobinsSorted: '+ roundRobinsSorted);
                    System.debug('RRUList: '+RRUList);
                    
                    //Remove the assigned record id from the list of unassiged Ids
                    Integer index = this.Ids.indexOf(currRecord.Id);
                    if (index != -1) {
                        this.Ids.remove(index);
                    }
                }
            }
            
        }
        if(this.combinedCompIds != null)
            System.debug('This.combinedCompIds:'+this.combinedCompIds);
        if(compIds != null)
            System.debug('this.compIds: '+this.compIds);
        //Remove the engine record from the list 
        if(this.combinedCompIds !=null && (this.compIds == null || this.compIds.size()==0)&& this.combinedCompIds.size()>0){
            this.EngList.remove(0);
            this.compIds = new List<String>();
            for(String currComp:this.combinedCompIds){
                this.compIds.add(currComp);
            }
            System.debug('Refilling CompId and emptying engine');
        } 
        else if(this.combinedCompIds !=null && this.combinedCompIds.size() == 0){
            this.EngList.remove(0);
        }
        update objectList;
        update RRUList;
        
        System.debug('Ids:'+this.Ids);
        System.debug('EngList:'+ this.EngList);
        //Check the Ids and EngList not empty to enqueue a new job
        if(!this.Ids.isEmpty() && !this.EngList.isEmpty() && this.objectName != 'Opportunity'){
            System.debug('Entered to enqueue');
            system.enqueueJob(new ECSS_RoundRobinQueueable(this.ObjectName,this.Ids,this.EngList,this.compIds,this.combinedCompIds,this.checkManager));
        }
        else if(this.objectName == 'Opportunity' && !this.Ids.isEmpty() && !this.EngList.isEmpty() && !roundRobinsSorted.isEmpty() && objectList.size()>0 ){
            System.debug('Entered to enqueue');
            system.enqueueJob(new ECSS_RoundRobinQueueable(this.ObjectName,this.Ids,this.EngList,this.compIds,this.combinedCompIds,this.checkManager));
        }
    }
    
    public class UserSortWrapper implements Comparable {
        public Round_Robin_User__c usrRoundRobin {get; set;}
        public UserSortWrapper(Round_Robin_User__c usrRoundRobin) {
            this.usrRoundRobin = usrRoundRobin;
        }
        public Integer compareTo(Object compareTo) {
            UserSortWrapper compareToUser = (UserSortWrapper)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (this.usrRoundRobin.Counter__c  > compareToUser.usrRoundRobin.Counter__c ) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (this.usrRoundRobin.Counter__c  < compareToUser.usrRoundRobin.Counter__c ) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }
}