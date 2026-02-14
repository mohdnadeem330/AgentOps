trigger OpportunityTrigger on Opportunity (before insert,before update,after insert,after update) {

    try {     if(!UtilitiesWithoutSharing.bypassOpportunityTrigger){
        new OpportunityTriggerHandler().run('Opportunity');} } catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'OpportunityTrigger','OpportunityTriggerHandler',''));throw e;} 

}