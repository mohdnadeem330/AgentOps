trigger LeadTrigger on Lead (after insert, after update, before insert, before update) {
    
    try {
        if(!LeadFirstMethodOfContactService.skipLeadTrigger){
        	new LeadTriggerHandler().run('Lead');
        }
    } catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'LeadTrigger','LeadTriggerHandler','')); throw e; }   
}