/**********************************************************************************************************************
* Name              : ALD_ProfilePermissionSetAutomation                                                        
* Description       : Automate the permission set and permission set license assignment to user
* Test Class		: ALD_ProfilePermissionSetAutomationTest
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun / 23 June 2023
******************************************************************************************************************/
public class ALD_ProfilePermissionSetAutomation 
{
    public static void grantUserLevelAssignments(Set<Id> userIdsSet)
    {
        List<User> userList = [SELECT Id, ProfileName__c FROM User WHERE ID IN :userIdsSet];
        try
        {
            Map<String, UserProfileMapping__mdt> getMappingByProfileName 			= new Map<String, UserProfileMapping__mdt>();
            Map<String, PermissionSetLicense> getPSLbyDevName 						= new Map<String, PermissionSetLicense>();
            Map<String, PermissionSet> getPSbyDevName 								= new Map<String, PermissionSet>();
            Map<String, String> assignedPSLByUserId									= new Map<String, String>();
            Map<String, String> assignedPSByUserId									= new Map<String, String>();
            List<PermissionSetLicenseAssign> permissionSetLicenseListToBeAssigned 	= new List<PermissionSetLicenseAssign>();
            List<PermissionSetAssignment> permissionSetListToBeAssigned 			= new List<PermissionSetAssignment>();
            List<UserProfileMapping__mdt> userProfileMetaData						= new List<UserProfileMapping__mdt>();
            Set<String> permissionSetLicenseDevName 								= new Set<String>();
            Set<String> permissionSetDevName 										= new Set<String>();
            Set<String> getpermissionSetLicenseDevName 								= new Set<String>();
            Set<String> getpermissionSetDevName 									= new Set<String>();
            
            
            if(Test.isRunningTest()){
                userProfileMetaData 												= [SELECT Id,Label,ProfileName__c,PermissionSetAssignments__c,PermissionSetLicenseAssignments__c FROM UserProfileMapping__mdt WHERE DeveloperName = 'SalesManager'];
            }else{
                userProfileMetaData 												= [SELECT
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
            
            List<PermissionSetLicense> pslList 									= [SELECT
                                                                                   Id,
                                                                                   MasterLabel,
                                                                                   DeveloperName,
                                                                                   TotalLicenses,
                                                                                   UsedLicenses
                                                                                   FROM PermissionSetLicense
                                                                                   WHERE DeveloperName IN :getpermissionSetLicenseDevName];
            if(!pslList.isEmpty()){
                for(PermissionSetLicense singlePSL : pslList){
                    if((singlePSL.TotalLicenses - singlePSL.UsedLicenses) > 1)
                    getPSLbyDevName.put(singlePSL.DeveloperName, singlePSL);
                }
            }
            
            List<PermissionSet> psList 											= [Select
                                                                                   Id,
                                                                                   Name,
                                                                                   Label
                                                                                   FROM PermissionSet
                                                                                   WHERE Name IN : getpermissionSetDevName];
            if(!psList.isEmpty()){
                for(PermissionSet singlePS : psList){
                    getPSbyDevName.put(singlePS.Name, singlePS);
                }
            }
            
            // Newly added by Tharun - Get all PSL & PS for user
            for(PermissionSetLicenseAssign assignedPSL : [SELECT Id,PermissionSetLicenseId,AssigneeId 
                                                          FROM PermissionSetLicenseAssign 
                                                          WHERE AssigneeId IN :userIdsSet])
            {
                if(assignedPSLByUserId.containsKey(assignedPSL.AssigneeId)){
                    String PSLids = assignedPSLByUserId.get(assignedPSL.AssigneeId) +','+ assignedPSL.PermissionSetLicenseId;
                    assignedPSLByUserId.put(assignedPSL.AssigneeId, PSLids);
                }else{
                    assignedPSLByUserId.put(assignedPSL.AssigneeId, assignedPSL.PermissionSetLicenseId);
                }
            }
            for(PermissionSetAssignment assignedPS : [SELECT Id,PermissionSetId,AssigneeId
                                                          FROM PermissionSetAssignment 
                                                          WHERE AssigneeId IN :userIdsSet])
            {
                if(assignedPSByUserId.containsKey(assignedPS.AssigneeId)){
                    String PSids = assignedPSByUserId.get(assignedPS.AssigneeId) +','+ assignedPS.PermissionSetId;
                    assignedPSByUserId.put(assignedPS.AssigneeId, PSids);
                }else{
                    assignedPSByUserId.put(assignedPS.AssigneeId, assignedPS.PermissionSetId);
                }                         
            }
            // Newly added by Tharun
            
            
            for(User userSingle : userList){
                if(getMappingByProfileName.keySet().contains(userSingle.ProfileName__c)){
                    if(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetLicenseAssignments__c != null){
                        permissionSetLicenseDevName = new Set<String>(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetLicenseAssignments__c.split(','));
                        for(String perSetLicenseName : permissionSetLicenseDevName){
                            if(!getPSLbyDevName.isEmpty() && getPSLbyDevName.get(perSetLicenseName) != null){
                                if(assignedPSLByUserId.isEmpty() || !assignedPSLByUserId.get(userSingle.Id).contains(getPSLbyDevName.get(perSetLicenseName).Id)){
                                    PermissionSetLicenseAssign pslAssign	= new PermissionSetLicenseAssign();
                                    pslAssign.PermissionSetLicenseId		= getPSLbyDevName.get(perSetLicenseName).Id;
                                    pslAssign.AssigneeId					= userSingle.Id;
                                    permissionSetLicenseListToBeAssigned.add(pslAssign);
                                }
                            }
                        }
                    }
                    if(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetAssignments__c != null){
                        permissionSetDevName = new Set<String>(getMappingByProfileName.get(userSingle.ProfileName__c).PermissionSetAssignments__c.split(','));
                        for(String perSetName : permissionSetDevName){
                            if(!getPSbyDevName.isEmpty() && getPSbyDevName.get(perSetName) != null){
                                if(assignedPSByUserId.isEmpty() || !assignedPSByUserId.get(userSingle.Id).contains(getPSbyDevName.get(perSetName).Id)){
                                    PermissionSetAssignment psAssign		= new PermissionSetAssignment();
                                    psAssign.PermissionSetId				= getPSbyDevName.get(perSetName).Id;
                                    psAssign.AssigneeId						= userSingle.Id;
                                    permissionSetListToBeAssigned.add(psAssign);
                                }
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
                        for(Database.Error errPSL : srPSL.getErrors()){
                            List<Logger__c> loggerList = new List<Logger__c>();
                            System.debug('Error in PSL Assignments-'+errPSL.getStatusCode() + ': ' + errPSL.getMessage());
							//LoggerService.save(LoggerService.createApexLog(errPSL,'DML Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'));
                            LoggerService.aynchronousSave(JSON.serialize(loggerList.add(LoggerService.createApexLog(errPSL,'DML Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'))));
                        }
                    }
                }
            }
            
            if(!permissionSetListToBeAssigned.isEmpty()){
                Database.SaveResult[] srListPS = Database.insert(permissionSetListToBeAssigned, false);
                for (Database.SaveResult srPS : srListPS){
                    if (!srPS.isSuccess()){
                        for(Database.Error errPS : srPS.getErrors()){
                            List<Logger__c> loggerList = new List<Logger__c>();
                            System.debug('Error in PS Assignments-'+errPS.getStatusCode() + ': ' + errPS.getMessage());
							//LoggerService.save(LoggerService.createApexLog(errPS,'DML Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'));
							LoggerService.aynchronousSave(JSON.serialize(loggerList.add(LoggerService.createApexLog(errPS,'DML Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'))));
                        }
                    }
                }
            }
            
        }catch(Exception ex){
            System.debug('Exception in ALD_ProfilePermissionSetAutomation-------->>>' + ex);
            List<Logger__c> loggerList = new List<Logger__c>();
            //LoggerService.save(LoggerService.createApexLog(ex,'Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'));
            LoggerService.aynchronousSave(JSON.serialize(loggerList.add(LoggerService.createApexLog(ex,'Exception','ALD_ProfilePermissionSetAutomation','grantUserLevelAssignments'))));
        }
        
    }
    
}