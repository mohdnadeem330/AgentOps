trigger DocumentTrigger on Document__c (after insert, after update, before insert, before update) {
    
    try {
        new DocumentTriggerHandler().run('Document__c');

    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'DocumentTrigger','DocumentTriggerHandler',''));
    }   
}