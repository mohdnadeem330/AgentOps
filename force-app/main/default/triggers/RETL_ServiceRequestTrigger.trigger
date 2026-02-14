trigger RETL_ServiceRequestTrigger on RETL_Service_Request__c (after insert, after update) {
	if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Instantiate the handler and delegate the processing.
            RETL_ServiceRequestTriggerHandler handler = new RETL_ServiceRequestTriggerHandler(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
            handler.processYardiSync();
        }
    }
}