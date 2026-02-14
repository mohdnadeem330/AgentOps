trigger ServiceRequestTrigger on HexaBPM__Service_Request__c (after insert,before insert,after update,before update) {
    try {    
        if(!ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger){
            new ServiceRequestTriggerHandlerNew().run('HexaBPM__Service_Request__c');
        }
    } catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e,'ServiceRequestTrigger','ServiceRequestTriggerHandler',''));throw e;} 
}