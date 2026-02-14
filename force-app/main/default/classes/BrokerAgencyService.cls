/*
*********************************************************
Apex Class Name    : BrokerAgencyService
Created Date       : June 27 2025
@description       : This Class is used for Specfic for Broker Agency Service Requests
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class BrokerAgencyService {
    /*
    *********************************************************
    @Method Name    : updateAgencySrReferredByProfileName
    @author         : Tharun
    @description    : Method to update ReferredBy Profile Name ASF-1367
    @param          : List<HexaBPM__Service_Request__c>
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */ 
    public static void updateAgencySrReferredByProfileName(List<HexaBPM__Service_Request__c> agencySRs){
        Map<String, String> getProfileNameByName = new Map<String, String>();
        List<User> userList =  [SELECT id, Name, ProfileName__c 
                                FROM User 
                                WHERE profilename__c in ('Broker Manager','Sales Manager') 
                                ORDER BY Name ASC];
        for(User singleUser : userList){
            getProfileNameByName.put(singleUser.Name, singleUser.ProfileName__c);
        }
        for(HexaBPM__Service_Request__c sr : agencySRs){
            sr.ReferredByProfileName__c = getProfileNameByName.get(sr.ReferredBy__c) != null ? getProfileNameByName.get(sr.ReferredBy__c) : '' ;
        }
    }
}