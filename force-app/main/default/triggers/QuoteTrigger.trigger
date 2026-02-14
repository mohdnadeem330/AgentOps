trigger QuoteTrigger on Quote (before insert,before update,after insert,after update) {

    try {   new QuoteTriggerHandler().run('Quote'); } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'QuoteTrigger','QuoteTriggerHandler','')); throw e; }
    
}