trigger TopUpCommissionTrigger on TopUpCommission__c (before insert, before update) {
    
     if (TopUpCommissionTriggerHandler.skipTopUpCommissionTrigger) {
        return; // Skip execution if the flag is true
    }
    TopUpCommissionTriggerHandler handler = new TopUpCommissionTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsertMethod(Trigger.new, Trigger.newMap);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdateMethod(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
}