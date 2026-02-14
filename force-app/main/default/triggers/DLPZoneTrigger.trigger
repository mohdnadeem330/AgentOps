trigger DLPZoneTrigger on DLPZone__c (before insert,before update,after insert,after update) {

    try {   new DLPZoneTriggerHandler().run('DLPZone__c'); } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'DLPZoneTrigger','DLPZoneTriggerHandler','')); throw e; }
}