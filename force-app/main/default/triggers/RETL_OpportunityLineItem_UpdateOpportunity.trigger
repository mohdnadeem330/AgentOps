trigger RETL_OpportunityLineItem_UpdateOpportunity on OpportunityLineItem
(after insert, after update, after delete) {

    Set<Id> oppIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (OpportunityLineItem oli : Trigger.new) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }
    }

    if (Trigger.isDelete) {
        for (OpportunityLineItem oli : Trigger.old) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }
    }

    if (!oppIds.isEmpty()) {
        RETL_OpptyUnitNumberTriggerHandler.populateUnitNumbers(oppIds);
    }
}