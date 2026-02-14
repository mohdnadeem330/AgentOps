public class UpdateReferredByProfileBatch implements Database.Batchable<sObject> 
{   
    Map<String, String> getProfileNameByName = new Map<String, String>();
    
    public UpdateReferredByProfileBatch()
    {
        List<User> userList =  [SELECT id, Name, ProfileName__c FROM User 
                                WHERE profilename__c in ('Broker Manager','Sales Manager') 
                                ORDER BY Name ASC];
        for(User singleUser : userList){
            getProfileNameByName.put(singleUser.Name, singleUser.ProfileName__c);
        }
    }
    
    public List<HexaBPM__Service_Request__c> start(Database.BatchableContext bc)
    {
        List<HexaBPM__Service_Request__c> returnSrList = new List<HexaBPM__Service_Request__c>();
        
        returnSrList = [SELECT Id, Name, AccountName__c, ReferredBy__c, CreatedDate, ReferredByProfileName__c 
                        FROM HexaBPM__Service_Request__c 
                        WHERE RecordType.DeveloperName   = 'AgencyRegistration' 
                        AND ReferredBy__c != null
                        AND ReferredBy__c != 'No Referral'
                        AND ReferredByProfileName__c = null
                        ORDER BY CreatedDate ASC];
        System.debug('returnSrList--'+returnSrList);
        
        return returnSrList;
    }

    public void execute(Database.BatchableContext bc, List<HexaBPM__Service_Request__c>  srList)
    {
        List<HexaBPM__Service_Request__c> finalSrListToBeUpdated = new List<HexaBPM__Service_Request__c>();
        System.debug('getProfileNameByName---'+getProfileNameByName);
        
        for(HexaBPM__Service_Request__c sr : srList){
            sr.ReferredByProfileName__c = getProfileNameByName.get(sr.ReferredBy__c);
            finalSrListToBeUpdated.add(sr);
        }
        
        if(!finalSrListToBeUpdated.isEmpty()){
            Database.SaveResult[] srListUpdated = Database.update(finalSrListToBeUpdated, false);
        }
        
    }
    
    public void finish(Database.BatchableContext bc)
    {
        System.debug('Batch finish -> ');
    }

}