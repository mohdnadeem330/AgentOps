trigger ECSS_InvReqDetailTrigger  on Inventory_Request_Details__c  (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
    triggerEnabler = Trigger_Enabler__c.getValues('Inventory Request Details');
    if (triggerEnabler == null) {
        return;
    }
    
    if (Trigger.isBefore && Trigger.isInsert && triggerEnabler.Is_Before_Insert__c) {
    } else if (Trigger.isAfter && Trigger.isInsert && triggerEnabler.Is_After_Insert__c) {
    } else if (Trigger.isBefore && Trigger.isUpdate && triggerEnabler.Is_Before_Update__c) {
    } else if (Trigger.isAfter && Trigger.isUpdate && triggerEnabler.Is_After_Update__c) {
        ECSS_InvReqDetailTriggerHandler.isAfterUpdate(Trigger.Old, Trigger.New, Trigger.OldMap, Trigger.NewMap);
    } else if (Trigger.isBefore && Trigger.isDelete && triggerEnabler.Is_Before_Delete__c) {
    } else if (Trigger.isAfter && Trigger.isDelete && triggerEnabler.Is_After_Delete__c) {
    }
}