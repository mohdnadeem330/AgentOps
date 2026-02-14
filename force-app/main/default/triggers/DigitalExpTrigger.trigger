trigger DigitalExpTrigger on Communication_Preference__c (after insert, after update,before update,before insert) {
    
    try {
        new DigitalExpTriggerHandler().run('Communication_Preference__c'); } catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'DigitalExpTrigger','DigitalExpTriggerHandler',''));throw e;}   
}