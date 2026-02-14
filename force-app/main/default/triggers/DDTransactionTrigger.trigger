trigger DDTransactionTrigger on DDTransaction__c (before insert, after insert, after update, before update) {
   // try {    
        new DDTransactionTriggerHandler().run('DDTransaction__c');
        
   /* } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'DDTransactionTrigger','DDTransactionTriggerHandler',''));
        throw e;
    } */

}