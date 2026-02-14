trigger SessionControlTrigger on SessionControlEvent__e (after insert) {
    
    Set<Id> sessionIdSet = new Set<Id>();
    for (SessionControlEvent__e event : Trigger.new) {
        if(event.SessionId__c != null){
            sessionIdSet.add(event.SessionId__c);
        }
    }
    Database.delete([SELECT Id FROM AuthSession WHERE Id =: sessionIdSet], false);    
}