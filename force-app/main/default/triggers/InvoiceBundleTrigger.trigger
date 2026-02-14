trigger InvoiceBundleTrigger on InvoiceBundle__c (after insert, before update,after update, before delete, after delete) {
    
    try {
        new InvoiceBundleTriggerHandler().run('InvoiceBundle__c');} catch(Exception e) {  LoggerService.save(LoggerService.createApexLog(e,'InvoiceBundleTrigger','InvoiceBundleTrigger','')); throw e;
    } 
}