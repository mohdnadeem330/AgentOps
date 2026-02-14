/**********************************************************************************************************************
* Name               : ALD_BatchToAssignPSLandPS                                                        
* Description        : 
* Created By         : Tharun
* Test Class		 : ALD_ProfilePermissionSetAutomationTest
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           tdontha@aldar.com     19/05/2023      Initial Draft       
******************************************************************************************************************/
public class ALD_BatchToAssignPSLandPS implements Database.Batchable<sObject>, Database.Stateful
{
    Map<String, UserProfileMapping__mdt> getMappingByProfileName 		= new Map<String, UserProfileMapping__mdt>();
    List<Logger__c>	loggerList											= new List<Logger__c>();
    Set<String> getpermissionSetLicenseDevName 							= new Set<String>();
    Set<String> getpermissionSetDevName 								= new Set<String>();
    Set<Id> finalUserIds 												= new Set<Id>();
    
    public List<User> start(Database.BatchableContext bc)
    {
        List<User> finalUserListToBeReturned								= new List<User>();
        List<UserProfileMapping__mdt> userProfileMetaData;
        
        if(Test.isRunningTest()){
            userProfileMetaData  = [SELECT
                                    Id,
                                    Label,
                                    ProfileName__c,
                                    PermissionSetAssignments__c,
                                    PermissionSetLicenseAssignments__c
                                    FROM UserProfileMapping__mdt
                                    WHERE IsActive__c = true AND DeveloperName = 'SalesManager'];
        }
        else{
            userProfileMetaData 					= [SELECT
                                                       Id,
                                                       Label,
                                                       ProfileName__c,
                                                       PermissionSetAssignments__c,
                                                       PermissionSetLicenseAssignments__c
                                                       FROM UserProfileMapping__mdt
                                                       WHERE IsActive__c = true];
        }
        
        if(!userProfileMetaData.isEmpty()){
            for(UserProfileMapping__mdt singelMdt: userProfileMetaData){
                getMappingByProfileName.put(singelMdt.ProfileName__c, singelMdt);
                if(String.isNotBlank(singelMdt.PermissionSetLicenseAssignments__c)){
                    getpermissionSetLicenseDevName.addAll(new Set<String>(singelMdt.PermissionSetLicenseAssignments__c.split(',')));
                }
                if(String.isNotBlank(singelMdt.PermissionSetAssignments__c)){
                    getpermissionSetDevName.addAll(new Set<String>(singelMdt.PermissionSetAssignments__c.split(',')));
                }
            }
        }
        
        // Get all unfrozen and active users from the profiles
        List<UserLogin> userLoginList 										= [SELECT 
                                                                               Id,
                                                                               IsFrozen,
                                                                               UserId 
                                                                               FROM UserLogin 
                                                                               WHERE IsFrozen = false 
                                                                               AND UserId IN (SELECT 
                                                                                              Id 
                                                                                              FROM User 
                                                                                              WHERE ProfileName__c = :getMappingByProfileName.keySet() 
                                                                                              AND IsActive = true)];
        if(!userLoginList.isEmpty()){
            for(UserLogin userLSingle : userLoginList){
                finalUserIds.add(userLSingle.UserId);
            }
        }
        
        
        if(!finalUserIds.isEmpty()){
            finalUserListToBeReturned											= [SELECT
                                                                                   Id,
                                                                                   ProfileName__c
                                                                                   FROM User
                                                                                   WHERE Id IN :finalUserIds];
            
            System.debug('finalUserListToBeReturned----'+finalUserListToBeReturned);
        }
        return finalUserListToBeReturned;
    }
    
    public void execute(Database.BatchableContext bc, List<User> userList)
    {
        Map<String, PermissionSetLicense> getPSLbyDevName 						= new Map<String, PermissionSetLicense>();
        Map<String, PermissionSet> getPSbyDevName 								= new Map<String, PermissionSet>();
        List<PermissionSetLicenseAssign> permissionSetLicenseListToBeAssigned 	= new List<PermissionSetLicenseAssign>();
        List<PermissionSetAssignment> permissionSetListToBeAssigned 			= new List<PermissionSetAssignment>();
        Set<String> permissionSetLicenseDevName 								= new Set<String>();
        Set<String> permissionSetDevName 										= new Set<String>();
        
        //Query all PermissionSetLicense
        List<PermissionSetLicense> pslList 										= [SELECT
                                                                                   Id,
                                                                                   MasterLabel,
                                                                                   DeveloperName,
                                                                                   TotalLicenses,
                                                                                   UsedLicenses
                                                                                   FROM PermissionSetLicense
                                                                                   WHERE DeveloperName IN :getpermissionSetLicenseDevName LIMIT 100];
        if(!pslList.isEmpty()){
            for(PermissionSetLicense singlePSL : pslList){
                if((singlePSL.TotalLicenses - singlePSL.UsedLicenses) > 1)
                    getPSLbyDevName.put(singlePSL.DeveloperName, singlePSL);
            }
        }
        
        //Query all PermissionSet
        List<PermissionSet> psList 												= [Select
                                                                                   Id,
                                                                                   Name,
                                                                                   Label
                                                                                   FROM PermissionSet
                                                                                   WHERE Name IN : getpermissionSetDevName LIMIT 200];
        if(!psList.isEmpty()){
            for(PermissionSet singlePS : psList){
                getPSbyDevName.put(singlePS.Name, singlePS);
            }
        }
        
        for(User userSingle : userList){
            if(getMappingByProfileName.keySet().contains(userSingle.ProfileName__c)){
                if(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetLicenseAssignments__c != null){
                    permissionSetLicenseDevName = new Set<String>(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetLicenseAssignments__c.split(','));
                    for(String perSetLicenseName : permissionSetLicenseDevName){
                        if(!getPSLbyDevName.isEmpty() && getPSLbyDevName.get(perSetLicenseName) != null){
                            PermissionSetLicenseAssign pslAssign	= new PermissionSetLicenseAssign();
                            pslAssign.PermissionSetLicenseId		= getPSLbyDevName.get(perSetLicenseName).Id;
                            pslAssign.AssigneeId					= userSingle.Id;
                            permissionSetLicenseListToBeAssigned.add(pslAssign);
                        }
                    }
                }
                if(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetAssignments__c != null){
                    permissionSetDevName = new Set<String>(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetAssignments__c.split(','));
                    for(String perSetName : permissionSetDevName){
                        if(!getPSbyDevName.isEmpty() && getPSbyDevName.get(perSetName) != null){
                            PermissionSetAssignment psAssign		= new PermissionSetAssignment();
                            psAssign.PermissionSetId				= getPSbyDevName.get(perSetName).Id;
                            psAssign.AssigneeId						= userSingle.Id;
                            permissionSetListToBeAssigned.add(psAssign);
                        }
                    }
                }
            }
        }
        
        
        if(!permissionSetLicenseListToBeAssigned.isEmpty()){
            //Database methods - partial update - true, if any record fails then all records will fail (default)
            // 									  false, if any record fails then success records will be inserted
            Database.SaveResult[] srListPSL = Database.insert(permissionSetLicenseListToBeAssigned, false);
            
            // Iterate through each returned result
            for (Database.SaveResult srPSL : srListPSL){
                if (!srPSL.isSuccess()){
                    // Operation failed, so get all errors                
                    for(Database.Error errPSL : srPSL.getErrors()){
                        System.debug('Error in PSL Assignments-'+errPSL.getStatusCode() + ': ' + errPSL.getMessage());
                    }
                }
            }
        }
        
        if(!permissionSetListToBeAssigned.isEmpty()){
            Database.SaveResult[] srListPS = Database.insert(permissionSetListToBeAssigned, false);
            // Iterate through each returned result
            for (Database.SaveResult srPS : srListPS){
                if (!srPS.isSuccess()){
                    for(Database.Error errPS : srPS.getErrors()){
                        System.debug('Error in PS Assignments-'+errPS.getStatusCode() + ': ' + errPS.getMessage());
                    }
                }
            }
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch finish -> ');
    } 
}