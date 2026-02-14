trigger QualtricsResponseTrigger on QualtricsResponse__c (before insert, after insert, before Update, after Update) {
    //Monika: added after insert
    try
    {
      new QualtricsResponseTriggerHandler().run('QualtricsResponse__c');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'QualtricsResponseTrigger','QualtricsResponseTrigger',''));
        throw e;
    }  
}