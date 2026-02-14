trigger SalesOrderCancellationTrigger on SalesOrderCancellation__c (before update, before insert) {
    // try {
        new SalesOrderCancellationTriggerHandler().run('SalesOrderCancellation__c');
    // } catch(Exception e) { 
    //     LoggerService.save(LoggerService.createApexLog(e,'SalesOrderCancellationTrigger','SalesOrderCancellationTrigger',''));
    //     throw e;
    // } 
}