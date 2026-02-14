trigger OpportunityOfferLineTrigger on OpportunityOfferLine__c (before insert,before update,after insert,after update) {
    try { new OpportunityOfferLineTriggerHandler().run('OpportunityOfferLine__c'); } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'OpportunityOfferLineTrigger','OpportunityOfferLineTriggerHandler','')); throw e; }
}