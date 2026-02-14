trigger ResaleOfferTrigger on Resale_Offers__c  (after update, before update) {
    // try {
    //     new ResaleOfferTriggerHandler().run('Resale_Offers__c');
    // } catch(Exception e) {
    //     LoggerService.save(LoggerService.createApexLog(e,'ResaleOfferTrigger','ResaleOfferTrigger',''));
    //     throw e;
    // } 
    System.debug('#### IN RESALE TRIGGER');
    new ResaleOfferTriggerHandler().run('Resale_Offers__c');
}