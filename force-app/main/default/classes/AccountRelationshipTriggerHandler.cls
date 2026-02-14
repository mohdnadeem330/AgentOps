public with sharing class AccountRelationshipTriggerHandler extends TriggerHandler {
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {}
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        KYCValidityController.updateKYCvalidityOnARCleared(newList, oldMap);
    }
}