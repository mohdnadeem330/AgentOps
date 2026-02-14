trigger RETL_OrderItemTrigger on OrderItem (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RETL_OrderItemHelper.updateUnitNumbers(Trigger.new, null);
    }

    if (Trigger.isDelete) {
        RETL_OrderItemHelper.updateUnitNumbers(null, Trigger.old);
    }
}