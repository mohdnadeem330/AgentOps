trigger ShipmentRequestTrigger on ShipmentRequest__c (before insert, after insert, after update) {
    try {    
        new ShipmentRequestTriggerHandler().run('ShipmentRequest__c');
    } catch(Exception e) {
        LoggerService.save(LoggerService.addApexLog(e,'ShipmentRequestTrigger','ShipmentRequestTriggerHandler',''));
        throw e;
    } 
}