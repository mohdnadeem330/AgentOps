trigger SalesOrderRelationshipTrigger on Sales_Order_Relationship__c (before insert, after insert, before update, after update,before delete) {

    //ASF-3319, ASF-3320

    if(trigger.isInsert && trigger.isBefore){

        SalesOrderRelationshipTriggerHandler.onBeforeInsert(Trigger.new);

    }

    if(trigger.isInsert && trigger.isAfter){

        SalesOrderRelationshipTriggerHandler.onAfterInsert(Trigger.new);

    }

    if(trigger.isUpdate && trigger.isAfter){

        SalesOrderRelationshipTriggerHandler.onAfterUpdate(Trigger.new,Trigger.oldMap);

    }

    if(trigger.isBefore && trigger.isDelete){

        SalesOrderRelationshipTriggerHandler.onBeforeDelete(Trigger.old); // ASF-3480 changes 

    }

}