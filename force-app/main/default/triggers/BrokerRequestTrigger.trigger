trigger BrokerRequestTrigger on BrokerRequest__c (before insert, before update, after update, after insert) {
    try {  
        BrokerRequestTriggerHandler obj= new BrokerRequestTriggerHandler();
        obj.run('BrokerRequest__c');
    } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'BrokerRequestTrigger','BrokerRequestTriggerHandler','')); throw e;
    } 
}