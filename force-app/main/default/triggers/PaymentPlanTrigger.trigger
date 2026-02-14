trigger PaymentPlanTrigger on PaymentPlan__c (before update, After insert, after update) {
    try {new PaymentPlanTriggerHandler().run('PaymentPlan__c');} catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'PaymentPlanTrigger','PaymentPlanTrigger',''));throw e;}  
}