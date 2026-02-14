trigger ChecklistTrigger on Checklist__c (before insert,before update,after insert,after update) {

    try { new ChecklistTriggerHandler().run('Checklist__c');}catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'ChecklistTrigger ','ChecklistTriggerHandler','')); throw e; }
}