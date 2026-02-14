trigger HandoverDetailsTrigger on HandoverDetails__c (before insert,before update,after insert,after update) {
    try {    
        new HandoverDetailsTriggerHandler().run('HandoverDetails__c');} catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'HandoverDetailsTrigger','HandoverDetailsTrigger',''));throw e;
    } 
}