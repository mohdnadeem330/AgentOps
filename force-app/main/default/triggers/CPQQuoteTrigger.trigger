/**********************************************************************************************************************
* Name               : CPQQuoteTrigger                                                 
* Description        : Trigger for CPQ Quote
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           harohilla@aldar.com     14/01/2025      Initial Draft    
******************************************************************************************************************/
trigger CPQQuoteTrigger on SBQQ__Quote__c (after insert,after update, before insert) {

    try {  
        if (CPQQuoteTriggerHandler.isProcessing) {
            return;
        }  
        // Set the static variable to true to indicate the trigger is processing
        CPQQuoteTriggerHandler.isProcessing = true;
        new CPQQuoteTriggerHandler().run('SBQQ__Quote__c');
    }catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e,'CPQQuoteTrigger','CPQQuoteTrigger','')); throw e; }finally{CPQQuoteTriggerHandler.isProcessing = false;}
}