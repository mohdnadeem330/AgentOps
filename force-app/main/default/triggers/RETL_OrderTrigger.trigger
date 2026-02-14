trigger RETL_OrderTrigger on Order (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        RETL_OrderTriggerHandler.handleAfter(Trigger.new, Trigger.oldMap);
    }
}