trigger SalesOrderOtherChargesTrigger on SalesOrderOtherCharges__c (before insert,before update,after insert, after update) {
    try {
        new SalesOrderOtherChargesHandler().run('SalesOrderOtherCharges__c');} catch(Exception e) { LoggerService.save(LoggerService.createApexLog(e,'SalesOrderOtherChargesTrigger','SalesOrderOtherChargesTrigger',''));throw e;
    }  
}