public with sharing class UserTriggerHandler extends TriggerHandler {
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
    
        Set<ID> accountIDtoCalculate = new Set<ID>();
        set<id> markUserOffline = new set<ID>();
        
        Map<Id, Id> AccountIdWithagencyAdmin = new Map<Id, Id>();

        for (User userRecord : (List<User>)newList) {
            User oldUser = (User)oldmap.get(userRecord.Id);
            if(userRecord.AccountId !=null && userRecord.ProfileName__c != oldUser.ProfileName__c && ((userRecord.ProfileName__c.equals(Constants.AGENCY_ADMIN) || oldUser.ProfileName__c.equals(Constants.AGENCY_ADMIN)) || (userRecord.ProfileName__c.equals(Constants.AGENCY_ADMIN_PROFILE_LOGIN) || oldUser.ProfileName__c.equals(Constants.AGENCY_ADMIN_PROFILE_LOGIN))) ) {
                accountIDtoCalculate.add(userRecord.AccountId);
            }
            if(userRecord.isActive != oldUser.isActive && !userRecord.isActive){
                markUserOffline.add(userRecord.id);
            }
            if(userRecord.isActive != oldUser.isActive && userRecord.IsActive == true && (userRecord.ProfileName__c == Constants.AGENCY_ADMIN_PROFILE || userRecord.ProfileName__c == Constants.AGENCY_ADMIN_PROFILE_LOGIN)){
                AccountIdWithagencyAdmin.put(userRecord.AccountId, userRecord.Id);
            }
            
        }

        if(!AccountIdWithagencyAdmin.isEmpty()){
            ShareHelper.shareAccountRecordWithNewAgentCreated(AccountIdWithagencyAdmin, Constants.READ_ACCESS);
        }
        if(!accountIDtoCalculate.isEmpty()){
            validateAgencyParentContacts(accountIDtoCalculate);
        }
        if(!markUserOffline.isEmpty()){
            updateRoundRobinPreference(markUserOffline);
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {

        Map<Id, Id> AccountIdWithagencyAdmin = new Map<Id, Id>();
        
        for(User userRec : (List<User>)newList){

            if((userRec.ProfileName__c == Constants.AGENCY_ADMIN_PROFILE || userRec.ProfileName__c == Constants.AGENCY_ADMIN_PROFILE_LOGIN) && userRec.IsActive == true){
                AccountIdWithagencyAdmin.put(userRec.AccountId, userRec.Id);
            }

        }

        if(!AccountIdWithagencyAdmin.isEmpty()){
            ShareHelper.shareAccountRecordWithNewAgentCreated(AccountIdWithagencyAdmin, Constants.EDIT_ACCESS);
        }
    }
    
    
    @future
    public static void updateRoundRobinPreference(set<id> markUserOffline){
        RoundRobinAssignmentUtility.setAgentOffline(markUserOffline);
    }

    public static void validateAgencyParentContacts(set<id> accountIds){
        set<ID> accountRecordsToProcess = new set<ID>();
        for(Account accRecord : [select id,parentID from Account where parentID in :accountIds ]){
            accountRecordsToProcess.add(accRecord.parentID);
        }
        if(!accountRecordsToProcess.isEmpty()){
            AccountTriggerHandler.recalculateAccountRelationShip(accountRecordsToProcess);
        }
    }
    // accountRec = Select Id from Account where ParentId =: contact.AccountId
    // list<Contact> = Select Id from Contact where AccountId =: accountRec
    // 
    //  
}