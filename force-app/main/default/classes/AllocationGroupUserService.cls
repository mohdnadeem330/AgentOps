public class AllocationGroupUserService {

    /*
    * Add Allocation Group Users to the Public Group
    */
    @AuraEnabled(cacheable=false)
    public static void newAllocationGroupMembers(List<AllocationGroupUser__c> allocationGroupList){
        Set<Id> allocationGroupUserIds = new Set<Id>();

        for(AllocationGroupUser__c allocationGroupUserRec : allocationGroupList){
            if(allocationGroupUserRec.StartDate__c <= Date.Today() && allocationGroupUserRec.EndDate__c >= Date.Today()){
                allocationGroupUserIds.add(allocationGroupUserRec.Id);
            }
        }

        if(allocationGroupUserIds != null && !allocationGroupUserIds.isEmpty()){
            validateAllocationGroupEndDate(allocationGroupUserIds);
        }
        
    }

    @future
    public static void validateAllocationGroupEndDate(Set<Id> allocationGroupUserIds){

        Map<Id,Set<Id>> publicGroupUserMap = getPubliGroupUserMap(allocationGroupUserIds) ;

        if(publicGroupUserMap != null && !publicGroupUserMap.isempty()){
            addUsersToPublicGroup(publicGroupUserMap);
        }
    }

    public static  Map<Id,Set<Id>> getPubliGroupUserMap(Set<Id> allocationGroupUserIds){

        Map<Id,Set<Id>> publicGroupUserMap = new Map<Id,Set<Id>>();

        for(AllocationGroupUser__c allocationGroupUserRec : [SELECT Id,StartDate__c,EndDate__c,PublicGroupAssociated__c,User__c FROM AllocationGroupUser__c WHERE Id IN:allocationGroupUserIds AND PublicGroupAssociated__c != null]){
            String publicGroupId = allocationGroupUserRec.PublicGroupAssociated__c ;
                Set<Id> userIds  = publicGroupUserMap.containskey(publicGroupId) ? publicGroupUserMap.get(publicGroupId) : new Set<id>();
                userIds.add(allocationGroupUserRec.User__c);
                publicGroupUserMap.put(publicGroupId,userIds);
        }

        return publicGroupUserMap ;
    }

    public static void addUsersToPublicGroup(Map<Id,Set<Id>> publicGroupUserMap){
        List<GroupMember> groupMemberList = new List<GroupMember>();

        for(Id publicGroupId : publicGroupUserMap.keyset()){
            for(Id userId : publicGroupUserMap.get(publicGroupId)){
                groupMemberList.add(getGroupMember(userId,publicGroupId));
            }
        }

        if(groupMemberList != null && !groupMemberList.isEmpty()){
            insert groupMemberList;
        }

    }

    /*
    * Build Group Member Record
    */
    public static GroupMember getGroupMember(Id userId, Id publicGroupId){

        GroupMember groupMemberRec = new GroupMember();
        groupMemberRec.UserOrGroupId = userId ;
        groupMemberRec.GroupId = publicGroupId ;
        return groupMemberRec ; 
    }
    
    public static void deletedAllocationGroupMembers(List<AllocationGroupUser__c> allocationGroupList){
        Map<Id,Set<Id>> userPublicGroupMap = new Map<Id,Set<Id>>();
        List<AllocationGroupUserWrapper> allocationGroupUserWrapper = new List<AllocationGroupUserWrapper>();

        //---- Map Users to Public Group
        for(AllocationGroupUser__c allocationGroupUserRec :  allocationGroupList){
            Id publicGroupId = allocationGroupUserRec.PublicGroupAssociated__c ;
            Set<Id> userIds = new Set<Id>();
            if(userPublicGroupMap.containsKey(publicGroupId)){
                userIds = userPublicGroupMap.get(publicGroupId);
            }
            userIds.add(allocationGroupUserRec.User__c);
            userPublicGroupMap.put(publicGroupId,userIds);
        }
        
        for(Id publicGroupId : userPublicGroupMap.keyset()){
            allocationGroupUserWrapper.add(new AllocationGroupUserWrapper(publicGroupId,userPublicGroupMap.get(publicGroupId)));
        }

        if(allocationGroupUserWrapper != null && !allocationGroupUserWrapper.isempty()){
            if(!System.isBatch()){
                removeUsersGroupAllocationGroup(serializeJsonAGUserWarapper(allocationGroupUserWrapper));
            }
            else{
                removeUserAccess(serializeJsonAGUserWarapper(allocationGroupUserWrapper));
            }
            
        }
    }

    /*
    * Remove users from public group as future process
    */
    @future
    public static void removeUsersGroupAllocationGroup(String allocationGroupUserJSON){
        removeUserAccess(allocationGroupUserJSON);
    }


    /*
    * Remove users from public group
    */
    public static void removeUserAccess(String allocationGroupUserJSON){

        Map<Id,Set<Id>> userPublicGroupMap = new Map<Id,Set<Id>>();

        //---- Map Users to Public Group
        if(String.isNotEmpty(allocationGroupUserJSON)){
            for(AllocationGroupUserWrapper userRec : deserializeJsonAGUserWarapper(allocationGroupUserJSON)){
                userPublicGroupMap.put(userRec.publicGroupId,userRec.userIds);
            }
        }

        System.Debug('**Group Ids**'+userPublicGroupMap.keyset());

        //---- Get Public Group Members
        List<GroupMember> groupMemberList = [SELECT Id,GroupId,UserOrGroupId FROM GroupMember 
                                          WHERE GroupId =: userPublicGroupMap.keyset() LIMIT 5000];
        List<GroupMember> groupMemberListToDelete = new List<GroupMember>();

        //---- Check if access needs to be revoked
        for(GroupMember groupMember : groupMemberList){
            System.Debug(groupMember.UserOrGroupId+'**Group Id**'+groupMember.GroupId);
            
            if(userPublicGroupMap.get(groupMember.GroupId).contains(groupMember.UserOrGroupId)){
                groupMemberListToDelete.add(groupMember);
            }
        }
        //---- Delete group members
        if(groupMemberListToDelete != null && !groupMemberListToDelete.isempty()){
            delete groupMemberListToDelete;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<AllocationGroupUser__c> getAllocationGroupUsersQuery(String query) {
        List<AllocationGroupUser__c> records = Database.query(query);
        return records;
    }

    @AuraEnabled(cacheable=false) 
    public static list<AllocationGroupUser__c> prepareAllocationGroupUserId(String UserName, String AllocationGroupId){
        list<AllocationGroupUser__c> lstAllocationGroupUserId = new list<AllocationGroupUser__c>();
        lstAllocationGroupUserId.add([Select Id,StartDate__c from AllocationGroupUser__c where UserUsername__c =: UserName and AllocationGroup__c =: AllocationGroupId and (IsActive__c = true OR StartDate__c > TODAY) limit 1]);
        return lstAllocationGroupUserId;
    }


    public static void updatedAllocationGroupUsers(Map<Id, AllocationGroupUser__c> allocationGroupUserMap,  Map<Id, AllocationGroupUser__c> allocationGroupUserOldMap){

        Set<Id> allocationGroupuserIdsToShare = new Set<Id>();
        List<AllocationGroupUser__c> removeUsersList = new List<AllocationGroupUser__c>();

        for(Id allocationGroupUser : allocationGroupUserMap.keyset()){
            AllocationGroupUser__c oldAllocationGroupUserRec = allocationGroupUserOldMap.get(allocationGroupUser);
            AllocationGroupUser__c newAllocationGroupUserRec = allocationGroupUserMap.get(allocationGroupUser);

            //---- Check if End Date has been changed
            if(oldAllocationGroupUserRec.EndDate__c != newAllocationGroupUserRec.EndDate__c){
                if(newAllocationGroupUserRec.EndDate__c > System.today()){
                    allocationGroupuserIdsToShare.add(allocationGroupUser);
                }
                else if(newAllocationGroupUserRec.EndDate__c <= System.today() || newAllocationGroupUserRec.EndDate__c == null){
                    removeUsersList.add(newAllocationGroupUserRec);
                }
            }

            //---- Check if Start Date has been changed
            if(oldAllocationGroupUserRec.StartDate__c != newAllocationGroupUserRec.StartDate__c){
                if(newAllocationGroupUserRec.StartDate__c <= System.today() && newAllocationGroupUserRec.EndDate__c > System.today()){
                    allocationGroupuserIdsToShare.add(allocationGroupUser);
                }
                else if(newAllocationGroupUserRec.StartDate__c > System.today()){
                    removeUsersList.add(newAllocationGroupUserRec);
                }
            }

        }

        if(allocationGroupuserIdsToShare != null && !allocationGroupuserIdsToShare.isEmpty()){
            validateAllocationGroupEndDate(allocationGroupuserIdsToShare);
        }

        if(removeUsersList != null && !removeUsersList.isEmpty()){
            deletedAllocationGroupMembers(removeUsersList);
        }

    }

    //----- Wrapper to set the datatype as a JSON for inserting group members
    public class AllocationGroupUserWrapper{
        public id publicGroupId {get;set;}
        //public id allocationGroupId {get;set;}
        public set<id> userIds {get;set;}
        public AllocationGroupUserWrapper(Id publicGrpId, Set<Id> userIds){
            this.publicGroupId = publicGrpId;
            this.userIds = userIds;
            //this.allocationGroupId = allocationGroupId;
        }
    }

    //----- Serialize JSON wrapper
    public static string serializeJsonAGUserWarapper(List<AllocationGroupUserWrapper> allocationGroupUserJSON){
        return json.serialize(allocationGroupUserJSON);
    }
    
    //----- Deserialize to object
    public static List<AllocationGroupUserWrapper> deserializeJsonAGUserWarapper(String allocationGroupUserIds){
        return (List<AllocationGroupUserWrapper>)json.deserialize(allocationGroupUserIds,list<AllocationGroupUserWrapper>.Class);
    }

    public static List<AllocationGroupUser__c> getUserActiveAllocationGroup(){
        User loggedIdUser = Utilities.getLoggedInUserDetail();
        return [SELECT Id,Name,AllocationGroup__r.IsActive__c,AllocationGroup__r.Name FROM AllocationGroupUser__c WHERE AllocationGroup__r.IsActive__c =: true AND User__c =: loggedIdUser.Id];
    }

    public static Set<String> getUserAllocationGroupNames(){
        Set<String> allocationGroupNames = new Set<String>();
        for(AllocationGroupUser__c allocationGroupUser : getUserActiveAllocationGroup()){
            allocationGroupNames.add(allocationGroupUser.AllocationGroup__r.Name);
        }
        return allocationGroupNames ; 
    }

    public static AllocationGroupUsers getAllocationGroupUsers(Set<Id> reactiveAllocationGroupIds,Set<Id> endedAllocationGroupIds){

        AllocationGroupUsers allocationGroupUsers = new AllocationGroupUsers();
        if(reactiveAllocationGroupIds !=null)
            allocationGroupUsers.activeUserIds = new Set<Id>();
        if(endedAllocationGroupIds !=null)
            allocationGroupUsers.removeUsers = new List<AllocationGroupUser__c>();

        for(AllocationGroupUser__c user : [SELECT Id,Name,AllocationGroup__r.IsActive__c,AllocationGroup__r.Name,EndDate__c,IsActive__c,AllocationGroup__c,PublicGroupAssociated__c,User__c FROM AllocationGroupUser__c WHERE AllocationGroup__c IN: reactiveAllocationGroupIds OR AllocationGroup__c IN:endedAllocationGroupIds]){
            if(reactiveAllocationGroupIds!=null && reactiveAllocationGroupIds.contains(user.AllocationGroup__c) && user.EndDate__c >=Date.today()){
                allocationGroupUsers.activeUserIds.add(user.Id);
            }
            if(endedAllocationGroupIds!=null && endedAllocationGroupIds.contains(user.AllocationGroup__c) && user.EndDate__c >= Date.today()){
                allocationGroupUsers.removeUsers.add(user);
            }
        }

        return  allocationGroupUsers ;
    }

    public class AllocationGroupUsers{
        public Set<Id> activeUserIds                             {get;set;}
        public List<AllocationGroupUser__c> removeUsers          {get;set;}

        public AllocationGroupUsers(){
            this.activeUserIds = new Set<Id>();
            this.removeUsers = new List<AllocationGroupUser__c>();
        }
    }

}