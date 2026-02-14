trigger OffersPromotionsTrigger on OffersPromotions__c (After insert) {
    try {
        new OffersPromotionsTriggerHandler().run('OffersPromotions__c');
    } catch(Exception e) {
        LoggerService.save(LoggerService.createApexLog(e,'OfferTrigger','OfferTriggerHandler',''));
        throw e;
    }   
}