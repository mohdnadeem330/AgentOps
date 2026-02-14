/**********
*Name               : ParcelTrigger
*Description        : This trigger is used to populate orphan permit records which are not linked with any parcel
*Issue Detail       : The Tasareeh API occasionally returns the child data first. The parent (parcel) get sent 
					  later based on the status update. To link the children for which a parcel has not been found, 
					  we need to write this trigger.
*****************/

trigger ParcelTrigger on Parcel__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ParcelTriggerHandler.handleAfterInsert(Trigger.newMap);
    }

}