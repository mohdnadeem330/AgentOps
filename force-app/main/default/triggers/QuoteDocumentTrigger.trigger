trigger QuoteDocumentTrigger on SBQQ__QuoteDocument__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        QuoteDocumentTriggerHandler.handleAfterInsert(Trigger.new);
    }
}