trigger BuildingSectionTrigger on BuildingSection__c (before update, after update) {

    try {    
        new BuildingSectionTriggerHandler().run('BuildingSection__c');} catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'BuildingSectionTrigger','BuildingSectionTriggerHandler',''));throw e;
    } 
}