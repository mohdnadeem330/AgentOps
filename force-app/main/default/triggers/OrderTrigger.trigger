trigger OrderTrigger on Order (after update, before insert, after insert) {
    try {    
        CalloutToMuleSoft.isFromTrigger = true; //INTEG_ISSUE_FIX_SS
        new OrderTriggerHandler().run('Order'); 
        CalloutToMuleSoft.isFromTrigger = false; //INTEG_ISSUE_FIX_SS
    }
    catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'OrderTrigger','OrderTriggerHandler','')); throw e; }
}