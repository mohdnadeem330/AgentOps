trigger ReceiptAcknowledgementTrigger on ReceiptAcknowledgement__c (before insert, after insert,before update, after update,before delete) {
    try {
        // FIN-82: Check both flags to prevent trigger execution during specific operations
        if(!DDTransactionResponseHandler.stopExecuteReceiptAckTrigger && !ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger){
            new ReceiptAcknowledgementTriggerHandler().run('ReceiptAcknowledgement__c');
       }
      
    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'ReceiptAcknowledgementTrigger','ReceiptAcknowledgementTriggerHandler',''));
        throw e;
    } 
}