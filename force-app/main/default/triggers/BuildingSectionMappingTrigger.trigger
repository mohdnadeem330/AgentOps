trigger BuildingSectionMappingTrigger on BuildingSectionMapping__c (after insert, after delete) {
    try {new BuildingSectionMappingTriggerHandler().run('BuildingSectionMapping__c');} catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'BuildingSectionMappingTrigger','BuildingSectionMappingTrigger',''));throw e;}  
}