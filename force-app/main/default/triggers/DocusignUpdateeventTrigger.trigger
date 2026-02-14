trigger DocusignUpdateeventTrigger on DocusignUpdateEvent__e (after insert) {
 DocusignUpdateEventTriggerHandler.onAfterInsert(Trigger.New);

}