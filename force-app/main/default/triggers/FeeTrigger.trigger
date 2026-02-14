/**********
*Name               : FeeTrigger
*Description        : This trigger is used to identify skipped fees for TASAREEH. Skipped fee amount will be calculated from 
					  service request that has related fee records with CREDITED status only.The Parent Service request 
					  shouldn't have any INVOICED Fees. If duplicate exists,consider only latest fee apply date records.		
*****************/

trigger FeeTrigger on Fees__c (after insert,after update) {
     if (Trigger.isAfter && Trigger.isInsert) {
        FeeTriggerHandler.handleAfterInsert(Trigger.newMap);
    }
     if (Trigger.isAfter && Trigger.isUpdate) {
        FeeTriggerHandler.handleAfterUpdate(Trigger.newMap,trigger.oldMap);
    }

}