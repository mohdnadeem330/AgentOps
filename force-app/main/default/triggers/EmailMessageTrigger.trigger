trigger EmailMessageTrigger on EmailMessage (before insert,before delete,after insert) {
    
    try 
    {
        if(Trigger.isBefore){
            if(Trigger.isInsert || Trigger.isDelete){
                new EmailMessageTriggerHandler().run('EmailMessage');
            }
        }else if(Trigger.isAfter){
            if(Trigger.isInsert){
                new EmailMessageTriggerHandler().run('EmailMessage');
            }
        }
    } 
    catch(Exception e) { LoggerService.save(LoggerService.createApexLog(e,'EmailMessageTrigger','EmailMessageTrigger',''));throw e; }  
}