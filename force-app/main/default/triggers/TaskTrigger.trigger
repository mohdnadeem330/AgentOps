trigger TaskTrigger on Task (after update, after insert , before delete) {
    
    try {
        new TaskTriggerHandler().run('Task');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'TaskTrigger','TaskTrigger',''));
        throw e;
    }  
}