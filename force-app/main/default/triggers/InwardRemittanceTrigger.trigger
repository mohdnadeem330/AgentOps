trigger InwardRemittanceTrigger on Inward_Remittance__c (before insert, before update) {
    try { new InwardRemittanceTriggerHandler().run('Inward_Remittance__c'); } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'InwardRemittanceTrigger','InwardRemittanceTriggerHandler','')); throw e; }
}