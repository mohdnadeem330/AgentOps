trigger VisitDetailTrigger on VisitDetail__c (before insert,before update,after insert,after update) {
    try { new VisitDetailTriggerHandler().run('VisitDetail__c'); } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'OpportunityOfferLineTrigger','OpportunityOfferLineTriggerHandler','')); throw e; }
}