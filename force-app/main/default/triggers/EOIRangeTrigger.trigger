trigger EOIRangeTrigger on EOIRange__c (before insert, before update) {
    try {    
        new EOIRangeTriggerHandler().run('EOIRange__c');
    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'EOIRangerigger','EOIRangeTriggerHandler',''));
        throw e;
    } 
}