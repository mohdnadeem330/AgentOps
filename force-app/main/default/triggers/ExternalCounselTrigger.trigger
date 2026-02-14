trigger ExternalCounselTrigger on External_Counsel__c (before insert,before update) {
    try {
        new ExternalCounselTriggerHandler().run('External_Counsel__c');} catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'ExternalCounselTrigger','ExternalCounselTriggerHandler',''));throw e;}   
}