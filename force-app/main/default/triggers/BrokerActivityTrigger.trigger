trigger BrokerActivityTrigger on BrokerActivities__c (After insert) {
    try {
        new BrokerActivityTriggerHandler().run('BrokerActivities__c');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'BrokerActivityTrigger','BrokerActivityTrigger',''));
        throw e;
    }  
}