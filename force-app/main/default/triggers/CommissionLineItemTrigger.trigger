trigger CommissionLineItemTrigger on CommissionLineItem__c (after insert, before update,after update) {
    try {
        new CommissionLineItemTriggerHandler().run('CommissionLineItem__c');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'CommissionLineItemTrigger','CommissionLineItemTrigger',''));
        throw e;
    }  
}