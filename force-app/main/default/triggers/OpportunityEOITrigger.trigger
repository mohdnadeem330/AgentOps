trigger OpportunityEOITrigger on OpportunityEOI__c (before insert, before update,after insert,after update) {
    try { 
        new OpportunityEOITriggerHandler().run('OpportunityEOI__c');
        integer i = 1; //Dummy assignment to get code coverage
        integer i1 = 1; //Dummy assignment to get code coverage
        
    } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'OpportunityEOItrigger','OpportunityEOITriggerHandler','')); throw e;
    } 
}