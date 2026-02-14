trigger SuspensionWarningTrigger on Suspensions_Warning__c (before insert, after insert,before update, after update,before delete) {
    new SuspensionWarningTriggerHandler().run('Suspensions_Warning__c');
}