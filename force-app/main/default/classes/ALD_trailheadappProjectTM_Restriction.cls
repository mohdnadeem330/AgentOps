/******************************************************************************************************************
* Name              : ALD_trailheadappProjectTM_Restriction                                                        
* Description       : 
* Method			: allowBookingForSelectedProject returns TRUE/FALSE
* Test Class		: ALD_trailheadProjectTM_RestrictionTest
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
public without sharing class ALD_trailheadappProjectTM_Restriction
{
    @AuraEnabled(cacheable=false)
    public static responseWrapDetails allowBookingForSelectedProject(String projectName)
    {
        try{
            ResponseWrapDetails  res = new ResponseWrapDetails();
            String TRAILHEAD_STATUS_COMPLETED 										= 'Completed';
            String TRAILHEAD_STATUS_IN_PROGRESS										= 'In Progress';
            Set<Id> trailMixIdsForSelectedProject									= new Set<Id>();
            Set<Id> finalUncompletedTrailmixIds										= new Set<Id>();
            Map<String, TrailmixProjectRestrictionException__c> getResExcepByUser 	= new Map<String, TrailmixProjectRestrictionException__c>();
            Map<String, TrailmixProjectRestrictionException__c> getResExcepByAgency = new Map<String, TrailmixProjectRestrictionException__c>();
            List<trailheadapp__User_Trailmix__c> userAssignedToTrailmixList 		= new List<trailheadapp__User_Trailmix__c>();
            
            List<TrailmixProjectRestriction__c> allProjectRestrictionList	= [SELECT
                                                                               Id,
                                                                               Name,
                                                                               Project__c,
                                                                               Trailmix__c,
                                                                               TrailmixName__c,
                                                                               (SELECT Id,
                                                                                User__c,
                                                                                Agency__c,
                                                                                ValidFrom__c, 
                                                                                ValidTill__c 
                                                                                FROM Trailmix_Project_Restriction_Exceptions__r)
                                                                               FROM TrailmixProjectRestriction__c
                                                                               WHERE Project__c = :projectName];
            System.debug('allProjectRestrictionList:::'+allProjectRestrictionList);
            
            //There is a restriction for the selected project in TrailmixProjectRestriction__c
            if(!allProjectRestrictionList.isEmpty()){
                for(TrailmixProjectRestriction__c tmRest : allProjectRestrictionList){
                    if(tmRest.Trailmix_Project_Restriction_Exceptions__r != null){
                        for(TrailmixProjectRestrictionException__c resExcep: tmRest.Trailmix_Project_Restriction_Exceptions__r){
                            if(resExcep.User__c != null){
                                getResExcepByUser.put(resExcep.User__c, resExcep);
                            }
                            if(resExcep.Agency__c != null){
                                getResExcepByAgency.put(resExcep.Agency__c, resExcep);
                            }
                        }
                    }
                    trailMixIdsForSelectedProject.add(tmRest.Trailmix__c);
                }
            }else{
                //No restriction for selected project, hence ANY user shlould be able to proceed booking
                res.allowBooking = TRUE;
                return res;
            }
            
            
            // Check for the loggged in user has any entry in TrailmixProjectRestrictionException__c
            if(!getResExcepByUser.isEmpty()){
                String loggedInUserId = UserInfo.getUserId();
                if(getResExcepByUser.containsKey(loggedInUserId)){
                    Datetime currentDateTime	= System.now();
                    Datetime exceptionValidFROM = getResExcepByUser.get(loggedInUserId).ValidFrom__c;
                    Datetime exceptionValidTILL = getResExcepByUser.get(loggedInUserId).ValidTill__c;
                    if(exceptionValidFROM != null && exceptionValidTILL != null){
                        if(currentDateTime > exceptionValidFROM && currentDateTime < exceptionValidTILL){
                            res.allowBooking = TRUE;
                            return res;
                        }
                    }else{
                        res.allowBooking = TRUE;
                        return res;
                    }
                }
            }
            
            // Added after First Technical Go-Live
            // Check for the loggged in user's Agency has any entry in TrailmixProjectRestrictionException__c
            if(!getResExcepByAgency.isEmpty()){
                String loggedInUserAccountId = [SELECT Id, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.AccountId;
                System.Debug('loggedInUserAccountId-----'+loggedInUserAccountId);
                if(getResExcepByAgency.containsKey(loggedInUserAccountId)){
                    Datetime currentDateTime	= System.now();
                    Datetime exceptionValidFROM = getResExcepByAgency.get(loggedInUserAccountId).ValidFrom__c;
                    Datetime exceptionValidTILL = getResExcepByAgency.get(loggedInUserAccountId).ValidTill__c;
                    if(exceptionValidFROM != null && exceptionValidTILL != null){
                        if(currentDateTime > exceptionValidFROM && currentDateTime < exceptionValidTILL){
                            res.allowBooking = TRUE;
                            return res;
                        }
                    }else{
                        res.allowBooking = TRUE;
                        return res;
                    }
                }
            }
            // Added after First Technical Go-Live
            
            //Get all UserTrailmix records assigned to loggedin User
            if(trailMixIdsForSelectedProject.size() > 0){
                userAssignedToTrailmixList 								= [SELECT
                                                                           Id,
                                                                           trailheadapp__User__r.Name,
                                                                           TrailmixName__c,
                                                                           trailheadapp__Trailmix__c,
                                                                           trailheadapp__User__c,
                                                                           trailheadapp__Status__c
                                                                           FROM trailheadapp__User_Trailmix__c 
                                                                           WHERE trailheadapp__Trailmix__c 
                                                                           IN :trailMixIdsForSelectedProject  
                                                                           AND trailheadapp__User__c = :UserInfo.getUserId()];
            }
            
            if(userAssignedToTrailmixList.isEmpty())
            {
                if(!allProjectRestrictionList.isEmpty()){
                    for(TrailmixProjectRestriction__c tmRest : allProjectRestrictionList){
                        finalUncompletedTrailmixIds.add(tmRest.Trailmix__c);
                    }
                }
            }
            
            if(!userAssignedToTrailmixList.isEmpty()){
                Set<Id>	trailmixesNotAssigned							= new Set<Id>();
                trailmixesNotAssigned.addAll(trailMixIdsForSelectedProject);
                for(trailheadapp__User_Trailmix__c singleUTM : userAssignedToTrailmixList){
                    if(trailMixIdsForSelectedProject.contains(singleUTM.trailheadapp__Trailmix__c)){
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
            
            if(finalUncompletedTrailmixIds.size() > 0){
                List<trailheadapp__Trailmix__c> userTMList 				=  [SELECT
                                                                            Id,
                                                                            Name,
                                                                            trailheadapp_INT_SSO_URL__c,
                                                                            trailheadapp_EXT_SSO_URL__c
                                                                            FROM trailheadapp__Trailmix__c
                                                                            WHERE ID IN :finalUncompletedTrailmixIds];
                res.trailMixRecords = userTMList; 
            }else{
                res.allowBooking = TRUE;
                return res;
            }
            return res;
            
        }catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'Exception','ALD_trailheadappProjectTM_Restriction','allowBookingForSelectedProject'));
            return null;
        }
    }
    
    public class ResponseWrapDetails 
    {
        @AuraEnabled
        public Boolean allowBooking = false;
        @AuraEnabled
        public List<trailheadapp__Trailmix__c> trailMixRecords;
    }
    
}