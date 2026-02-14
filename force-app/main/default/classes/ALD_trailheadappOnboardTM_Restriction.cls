/******************************************************************************************************************
* Name              : ALD_trailheadappOnboardTM_Restriction                                                        
* Description       : 
* Method			: 
* Test Class		: ALD_trailheadOnboardTM_RestrictionTest
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
public without sharing class ALD_trailheadappOnboardTM_Restriction 
{
    public static UserOnboardedWrapper onboardResponse				= new UserOnboardedWrapper();
    
    //projectName parameter is required when bookingAppointment else empty can be passed
    @AuraEnabled(cacheable=false)
    public static UserOnboardedWrapper checkUserOnboarded(String featureSelected, String projectName)
    {
        String loggedInUserId 										= UserInfo.getUserId();
        User userRecord 											= [SELECT 
                                                                       Id,
                                                                       Name,
                                                                       trailheadapp_Onboarded__c
                                                                       FROM User
                                                                       WHERE Id = : loggedInUserId];
        if(userRecord != null){
            if(userRecord.trailheadapp_Onboarded__c){
                onboardResponse.userOnboarded = true;
                return onboardResponse;
            }else{
                checkUserFeatureRestriction(featureSelected, projectName);
            }
        }
        return onboardResponse;
    }
    
    
    public static UserOnboardedWrapper checkUserFeatureRestriction(String featureSelected, String projectName)
    {
        Set<Id> trailMixIdsForOnBoarding							= new Set<Id>();
        Set<Id> trailMixIdsForProjects								= new Set<Id>();
		Set<Id> trailMixIdsFinal									= new Set<Id>();
        Set<Id> finalUncompletedTrailmixIds							= new Set<Id>();

        List<trailheadapp__User_Trailmix__c> userAssignedToTrailmixList 		= new List<trailheadapp__User_Trailmix__c>();
        String TRAILHEAD_STATUS_COMPLETED 							= 'Completed';
        String TRAILHEAD_STATUS_IN_PROGRESS							= 'In Progress';
        
        String loggedInUserProfileName								= [SELECT 
                                                                       Id, 
                                                                       Name 
                                                                       FROM Profile
                                                                       WHERE Id =: UserInfo.getProfileId()].Name;
        List<Trailmix_Feature_Restriction__c> trailmixFeatureRest 	= [SELECT
                                                                       Id,
                                                                       Name,
                                                                       Feature__c,
                                                                       ProfileName__c,
                                                                       Trailmix__r.Name,
                                                                       Trailmix__c
                                                                       FROM Trailmix_Feature_Restriction__c
                                                                       WHERE Onboarding_Restriction__c = true
                                                                       AND Trailmix__c != NULL
                                                                       AND ProfileName__c =:loggedInUserProfileName
                                                                       AND Feature__c INCLUDES (:featureSelected)];
        System.debug('trailmixFeatureRest::'+trailmixFeatureRest);
        if(trailmixFeatureRest.isEmpty()){
            onboardResponse.userOnboarded = true;
            return onboardResponse;
        }else{
            //If there are multiple on boarding trailmixes
            for(Trailmix_Feature_Restriction__c featureRest : trailmixFeatureRest){
                trailMixIdsForOnBoarding.add(featureRest.Trailmix__c);
            }
        }
        
        // ***Below list is created only to show user a list of all the courses assigned before on boarding.
        // Purely for Book Appointment action
        
        if(String.isNotBlank(projectName)){
            List<TrailmixProjectRestriction__c> allProjectRestrictionList	= [SELECT
                                                                               Id,
                                                                               Name,
                                                                               Trailmix__c,
                                                                               Project__c,
                                                                               (SELECT Id,
                                                                                User__c, 
                                                                                ValidFrom__c, 
                                                                                ValidTill__c 
                                                                                FROM Trailmix_Project_Restriction_Exceptions__r)
                                                                               FROM TrailmixProjectRestriction__c
                                                                               WHERE Project__c = :projectName];
            if(allProjectRestrictionList.size() > 0){
                for(TrailmixProjectRestriction__c projRest : allProjectRestrictionList){
                    if(projRest.Trailmix_Project_Restriction_Exceptions__r.size() > 0){
                        for(TrailmixProjectRestrictionException__c resExcep: projRest.Trailmix_Project_Restriction_Exceptions__r){
                            if(resExcep.User__c != null && String.valueOf(resExcep.User__c).equals(UserInfo.getUserId())){
                                if(resExcep.ValidFrom__c != null && resExcep.ValidTill__c != null){
                                    if(System.now() > resExcep.ValidFrom__c && System.now() < resExcep.ValidTill__c){
                                    }else{
                                        trailMixIdsForProjects.add(projRest.Trailmix__c);
                                    }
                                }
                                break;
                            }else{
                                trailMixIdsForProjects.add(projRest.Trailmix__c);
                            }
                        }
                    }
                    trailMixIdsForProjects.add(projRest.Trailmix__c);
                }
            }
        }
        // ***Above list is created only to show user a list of all the courses assigned before on boarding.
        
        
        //Get records on all Trailmixes assigned to loggedin User
        if(trailMixIdsForOnBoarding.size() > 0){
            userAssignedToTrailmixList 								= [SELECT
                                                                       Id,
                                                                       trailheadapp__User__r.Name,
                                                                       TrailmixName__c,
                                                                       trailheadapp__Trailmix__c,
                                                                       trailheadapp__User__c,
                                                                       trailheadapp__Status__c
                                                                       FROM trailheadapp__User_Trailmix__c 
                                                                       WHERE trailheadapp__Trailmix__c 
                                                                       IN :trailMixIdsForOnBoarding  
                                                                       AND trailheadapp__User__c = :UserInfo.getUserId()];
        }
        
        if(userAssignedToTrailmixList.isEmpty())
        {
            List<Trailmix_Feature_Restriction__c> sobjRec = new List<Trailmix_Feature_Restriction__c>();
            if(!trailmixFeatureRest.isEmpty()){
                for(Trailmix_Feature_Restriction__c tmFeatureRest : trailmixFeatureRest){
                    finalUncompletedTrailmixIds.add(tmFeatureRest.Trailmix__c);
                }
            }
        }
        
        
        
        if(!userAssignedToTrailmixList.isEmpty()){
            Set<Id>	trailmixesNotAssigned							= new Set<Id>();
            trailmixesNotAssigned.addAll(trailMixIdsForOnBoarding);
            for(trailheadapp__User_Trailmix__c singleUTM : userAssignedToTrailmixList){
                if(trailMixIdsForOnBoarding.contains(singleUTM.trailheadapp__Trailmix__c)){
                    if(singleUTM.trailheadapp__Status__c == TRAILHEAD_STATUS_IN_PROGRESS){
                        finalUncompletedTrailmixIds.add(singleUTM.trailheadapp__Trailmix__c);
                    }
                    //if(singleUTM.trailheadapp__Status__c == TRAILHEAD_STATUS_COMPLETED){}
                    trailmixesNotAssigned.remove(singleUTM.trailheadapp__Trailmix__c);
                }
            }
            if(trailmixesNotAssigned.size() > 0){
                finalUncompletedTrailmixIds.addAll(trailmixesNotAssigned);
            }
        }
        
        
        if(!trailMixIdsForProjects.isEmpty()){
            finalUncompletedTrailmixIds.addAll(trailMixIdsForProjects);
        }
        
        
        if(finalUncompletedTrailmixIds.size() > 0){
            List<trailheadapp__Trailmix__c> userTMList 				=  [SELECT
                                                                        Id,
                                                                        Name,
                                                                        trailheadapp_INT_SSO_URL__c,
                                                                        trailheadapp_EXT_SSO_URL__c
                                                                        FROM trailheadapp__Trailmix__c
                                                                        WHERE ID IN :finalUncompletedTrailmixIds];

            onboardResponse.onBoardtrailMixRecords = userTMList;
        }else{
            onboardResponse.userOnboarded = TRUE;
            return onboardResponse;
        }
        
        return onboardResponse;
    }
    
    public class UserOnboardedWrapper 
    {
        @AuraEnabled
        public Boolean userOnboarded = false;
        @AuraEnabled
        public List<trailheadapp__Trailmix__c> onBoardtrailMixRecords;
    }
    
}