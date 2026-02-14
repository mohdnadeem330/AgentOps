public class ECSS_ProjectCommissionTriggerHandler {
    
    public static void handleBeforeInsert(List<ECSS_ProjectCommission__c> newList) {
    ECSS_ProjectCommissionHelper.checkForDuplicates(newList, null);
}

    public static void handleAfterInsert(List<ECSS_ProjectCommission__c> newList, Map<Id, ECSS_ProjectCommission__c> newMap) {
     
    }
    
    public static void handleAfterUpdate(List<ECSS_ProjectCommission__c> newList, Map<Id, ECSS_ProjectCommission__c> oldMap, Map<Id, ECSS_ProjectCommission__c> newMap) {
       
    }
    
     public static void handleBeforeUpdate(List<ECSS_ProjectCommission__c> newList, Map<Id, ECSS_ProjectCommission__c> oldMap) {
        ECSS_ProjectCommissionHelper.checkForDuplicates(newList, oldMap);
    }
}