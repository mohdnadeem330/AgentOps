/**********************************************************************************************************************
* Name               : DirectDebitTrigger                                                        
* Description        : 
* Created By         : Tharun                                                   
******************************************************************************************************************/
trigger DirectDebitTrigger on DirectDebitRequest__c (before insert, after insert, before update, after update) {
   // try {    
        new DirectDebitTriggerHandler().run('DirectDebitRequest__c');
        
   /* } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'DirectDebitTrigger','DirectDebitTriggerHandler',''));
        throw e;
    } */
}