trigger UnitTrigger on Unit__c (after insert,after update, before update) {
  try { new UnitTriggerHandler().run('Unit__c'); } catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'UnitTrigger','UnitTriggerHandler','')); throw e; }
}