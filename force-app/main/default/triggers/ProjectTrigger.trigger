trigger ProjectTrigger on Project__c (After insert,After Update) {
    try {
        new ProjectTriggerHandler().run('Project__c');} catch(Exception e) { LoggerService.save(LoggerService.createApexLog(e,'ProjectTrigger','ProjectTrigger',''));throw e;
    }  
}