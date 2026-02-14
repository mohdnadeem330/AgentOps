public class UserTrailmixTriggerHandler extends TriggerHandler 
{
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) 
    {
        System.debug('Execute afterUpdateMethod--------');
        String TRAILHEAD_STATUS_COMPLETED 								= 'Completed';
        Map<String, String>	profilesMap									= new Map<String, String>();				
        Set<Id> allUserIdsCompletedTMs 									= new Set<Id>();
        Set<Id> assignedTrailmixes	 									= new Set<Id>();
        Set<String> allUserIdsProfileName 								= new Set<String>();
        Set<Id> allUserIdsToUpdate	 									= new Set<Id>();
        
        for (trailheadapp__User_Trailmix__c userTMRecord : (List<trailheadapp__User_Trailmix__c>)newList) 
        {
            trailheadapp__User_Trailmix__c oldUserTM = (trailheadapp__User_Trailmix__c)oldmap.get(userTMRecord.Id);
            if(userTMRecord.trailheadapp__User__c != null){
                if(userTMRecord.trailheadapp__Status__c == TRAILHEAD_STATUS_COMPLETED && userTMRecord.trailheadapp__Status__c != oldUserTM.trailheadapp__Status__c){
                    allUserIdsCompletedTMs.add(userTMRecord.trailheadapp__User__c);
                    assignedTrailmixes.add(userTMRecord.trailheadapp__Trailmix__c);
                }
            }
        }
        
        if(!allUserIdsCompletedTMs.isEmpty()){
            for(User userRecords : [select id, ProfileName__c  from User where Id = :allUserIdsCompletedTMs]){
                allUserIdsProfileName.add(userRecords.ProfileName__c);
            }
        }
        
        System.debug('allUserIdsProfileName::'+allUserIdsProfileName);
        List<Trailmix_Feature_Restriction__c> trailmixFeatureRestList = [SELECT
                                                                         Id,
                                                                         Name,
                                                                         Feature__c,
                                                                         ProfileName__c,
                                                                         Trailmix__c
                                                                         FROM Trailmix_Feature_Restriction__c
                                                                         WHERE Onboarding_Restriction__c = true
                                                                         AND Trailmix__c IN :assignedTrailmixes
                                                                         AND ProfileName__c IN :allUserIdsProfileName];
        if(!trailmixFeatureRestList.isEmpty()){
            allUserIdsToUpdate.addAll(allUserIdsCompletedTMs);
        }
        System.debug('allUserIdsToUpdate:::'+allUserIdsToUpdate);
        if(!allUserIdsToUpdate.isEmpty()){
            updateUsersOnBoarded(allUserIdsToUpdate);
        }
        
    }
    
    public static void updateUsersOnBoarded(Set<Id> userIdsReceived)
    {
        List<User> userListToUpdate = new List<User>();
        for(User userRecords : [SELECT Id, ProfileName__c, trailheadapp_Onboarded__c 
                                FROM User 
                                WHERE Id = :userIdsReceived])
        {
            userRecords.trailheadapp_Onboarded__c = TRUE;
            userListToUpdate.add(userRecords);
        }
        
        if(!userListToUpdate.isEmpty()){
            update userListToUpdate;
        }
        
    }

}