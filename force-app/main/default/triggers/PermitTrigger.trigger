/**********
*Name               : PermitTrigger
*Description        : This trigger is used to populate orphan child records which are not linked with any permit
*Issue Detail       : The Tasareeh API occasionally returns the child data first. The parent (permit) get sent 
					  later based on the status update. To link the children for which a permit has not been found, 
					  we need to write this trigger.
*****************/
trigger PermitTrigger on Permit__c (after insert){
    if (Trigger.isAfter && Trigger.isInsert) {
        PermitTriggerHandler.handleAfterInsert(Trigger.newMap);
    }
	
}