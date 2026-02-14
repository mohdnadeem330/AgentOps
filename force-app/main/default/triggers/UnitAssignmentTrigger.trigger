trigger UnitAssignmentTrigger on Unit_Assignment__c (before insert , after insert , before update,  after update, before delete, after delete, after undelete) {
    new UnitAssignmentTriggerHandler().run('Unit_Assignment__c');  
}