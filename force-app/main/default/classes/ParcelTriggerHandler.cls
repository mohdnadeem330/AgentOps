public class ParcelTriggerHandler {
     public static void handleAfterInsert(Map<Id, Sobject> newMap) {
         Set<Id> parentIds = newMap.keySet();
         String parentObj='Parcel__c';
         Set<String> childObj = new Set<String>{'Permit__c'};
         TasareehUpdateParentIdInChild batch= new TasareehUpdateParentIdInChild(parentIds,parentObj,childObj);
         Database.executeBatch(batch, 200);

}

}