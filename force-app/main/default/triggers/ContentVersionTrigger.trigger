trigger ContentVersionTrigger on ContentVersion (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        RETL_ContentVersionHandler.afterInsert(Trigger.new);
        //RETL_ContentVersionHandler.sendPushNotificationFromNotes(Trigger.new);
    }
}