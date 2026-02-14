trigger AllocationGroupTrigger on AllocationGroup__c (after insert,after update) {

    try {    
        new AllocationGroupTriggerHandler().run('AllocationGroup__c');

    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'AllocationGroupTrigger','AllocationGroupTriggerHandler',''));
        throw e;
    } 
}