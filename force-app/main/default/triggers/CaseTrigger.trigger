trigger CaseTrigger on Case (before insert,before update,after insert,after update) {
    try { Feature_Flag__mdt disableCaseTriggerHandlerNew = Feature_Flag__mdt.getInstance('Disable_CasetriggerHandlerNew');
          if(!disableCaseTriggerHandlerNew.Is_Disabled__c) { if(!CaseTriggerHandlerNew.isSkipCaseTrigger) { new CaseTriggerHandlerNew().run('Case'); } } else {if(!CaseTriggerHandler.isSkipCaseTrigger) { new CaseTriggerHandler().run('Case'); } }} catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'CaseTrigger','CaseTriggerHandler',''));throw e;}
}