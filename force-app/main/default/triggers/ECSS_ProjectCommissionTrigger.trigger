trigger ECSS_ProjectCommissionTrigger on ECSS_ProjectCommission__c 
    (before insert, before update, after insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ECSS_ProjectCommissionTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        ECSS_ProjectCommissionTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        ECSS_ProjectCommissionTriggerHandler.handleAfterInsert(Trigger.new, Trigger.newMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ECSS_ProjectCommissionTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
}