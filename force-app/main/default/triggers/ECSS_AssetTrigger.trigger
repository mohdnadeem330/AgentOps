trigger ECSS_AssetTrigger on Asset (before insert, after insert, after update) {
    try{}catch(Exception e){System.debug(e); }
    /*Trigger_Enabler__c triggerEnablerSettings = Trigger_Enabler__c.getValues('Asset');
	System.debug('Asset Trigger Enabler: '+triggerEnablerSettings);
    if (Trigger.isAfter && Trigger.isInsert && triggerEnablerSettings.Is_After_Insert__c) {
        System.debug(Trigger.new.size());
       ECSS_AssetTriggerHandler.handleAfterInsert(Trigger.new, Trigger.newMap);
    }

    if (Trigger.isBefore && Trigger.isInsert && triggerEnablerSettings.Is_Before_Insert__c) {
        System.debug(Trigger.new.size());
        System.debug('9');
        ECSS_AssetTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate && triggerEnablerSettings.Is_After_Update__c) {
        System.debug('Running after update logic for Asset');
        ECSS_AssetTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
    }*/
    
}