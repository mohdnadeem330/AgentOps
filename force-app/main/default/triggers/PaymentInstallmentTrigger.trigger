trigger PaymentInstallmentTrigger on PaymentInstallments__c (before update, after update) {
    try {    
        new PaymentInstallmentTriggerHandler().run('PaymentInstallments__c');} catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'PaymentInstallmentTrigger','PaymentInstallmentTriggerHandler',''));throw e;
    } 
}