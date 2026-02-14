trigger SalesOrderTrigger on SalesOrder__c (after insert,before insert,after update,before update) {
    try {    
        CalloutToMuleSoft.isFromTrigger = true; //INTEG_ISSUE_FIX_SS
        if(!CalloutToMuleSoft.updateSOSyncStatus){
            new SalesOrderTriggerHandler().run('SalesOrder__c');
        }
        CalloutToMuleSoft.isFromTrigger = false; //INTEG_ISSUE_FIX_SS

    } 
    catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'OpportunityUnitTrigger','OpportunityUnitTriggerHandler','')); throw e; }
}