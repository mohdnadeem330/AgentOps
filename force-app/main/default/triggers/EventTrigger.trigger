trigger EventTrigger on Event (before delete) {
    
    try {
        new EventTriggerHandler().run('Event');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'EventTrigger','EventTrigger',''));
        throw e;
    }  
}