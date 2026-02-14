trigger AccountTrigger on Account (before insert,before update,after insert,after update) {

    try {    
        CalloutToMuleSoft.isFromTrigger = true; //INTEG_ISSUE_FIX_SS
        if(ResaleConstants.RUN_ACCOUNT_TRIGGER_RESALE_SWITCH && !LeadFastTrackAccountService.skipAccountTrigger && !CampaignMemberController.skipAccountTrigger && !AccountTriggerHandler.skipAccountTrigger){
            new AccountTriggerHandler().run('Account');
        }
        CalloutToMuleSoft.isFromTrigger = false; //INTEG_ISSUE_FIX_SS
    }
    catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'AccountTrigger','AccountTriggerHandler','')); throw e; }
}