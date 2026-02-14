global class OfflineRequestDefaultOnlineOfflineBatch implements Database.Batchable<sObject>{
    Boolean isStart;
    Boolean isEnd;
    public OfflineRequestDefaultOnlineOfflineBatch(Boolean isStart, Boolean isEnd){
        this.isStart = isStart;
        this.isEnd = isEnd;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String salesManagerProfileName = 'Sales Manager';
        //String salesManagerSODICProfileName = 'Sales Manager - SODIC';//remove
        String query = 'SELECT Id,ProfileId, Profile.Name FROM User where (Profile.Name =:salesManagerProfileName) AND IsActive = true';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<User> scope){
        Set<Id> allUserIdSet = new Set<Id>();
        Set<Id> allUserIdSetToSetStatus = new Set<Id>();
        datetime startDateTime = system.now();
        String dayOfWeek = startDateTime.format('EEEE');
        for(User us: scope){
            allUserIdSet.add(us.id);
        }
      Set<Id> approvedOffineReqUsers = getOfflineApprovedRequests(allUserIdSet);
     // boolean isWorkingHours = OfflineRequestController.validateBusinesshours(dayOfWeek, startDateTime.time());
        for(User us: scope){
            if(!approvedOffineReqUsers.contains(us.Id)){
                allUserIdSetToSetStatus.add(us.id);
            }
        }
        if(!allUserIdSetToSetStatus.isEmpty() && isStart){
            RoundRobinAssignmentUtility.setAgentAvailable(allUserIdSetToSetStatus);
        }
        if(isEnd){
            RoundRobinAssignmentUtility.setAgentOffline(allUserIdSet);
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
    
    public static Set<Id> getOfflineApprovedRequests(Set<Id> userIds){
        Set<Id> approvedUserIdset = new Set<Id>();
        List<OfflineRequest__c> objOfflineRequestList = [SELECT 
                                                         Name,
                                                         Reason__c,
                                                         StartTime__c,
                                                         Status__c,
                                                         EndTime__c,
                                                         User__c
                                                         FROM OfflineRequest__c
                                                         WHERE User__c =: userIds
                                                         AND StartTime__c <=: system.now()
                                                         AND EndTime__c >=: system.now()
                                                         AND Status__c = 'Approved'
                                                         ORDER BY lastmodifiedDate];
        
        if(!objOfflineRequestList.isEmpty()){
            for(OfflineRequest__c offlineRequest: objOfflineRequestList){
                approvedUserIdset.add(offlineRequest.User__c);
            }
        }
        return approvedUserIdset;
    }
}