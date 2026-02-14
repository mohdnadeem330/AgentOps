trigger AllocationGroupUserTrigger on AllocationGroupUser__c (before delete,after insert,after update) {

    try {    
        new AllocationGroupUserTriggerHandler().run('AllocationGroupUser__c');

    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'AllocationGroupUserTrigger','AllocationGroupUserTriggerHandler',''));
        throw e;
    } 
}