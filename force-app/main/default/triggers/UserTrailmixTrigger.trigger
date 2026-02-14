trigger UserTrailmixTrigger on trailheadapp__User_Trailmix__c (before insert, before update, after update) {
    
	try {    
        UserTrailmixTriggerHandler obj;
        obj = new UserTrailmixTriggerHandler();
        obj.run('trailheadapp__User_Trailmix__c');
    } catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e,'UserTrailmixTrigger','UserTrailmixTriggerHandler',''));throw e;}
}