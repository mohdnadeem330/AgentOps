trigger UserTrigger on User (before insert,before update,after insert,after update) {

    try {    
        UserTriggerHandler obj= new UserTriggerHandler();
        obj.run('User');
    } catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e,'UserTrigger','UserTriggerHandler',''));throw e;}
}