trigger ReceiptAllocationTrigger on ReceiptAllocation__c (before insert,before update,after insert,after update) {

    try {    
        // FIN-140: Check flag to prevent trigger execution during specific operations
        // Added by Sai Kumar
        if(!ReceiptAllocationTriggerHandler.skipReceiptAllocationTrigger){
            CalloutToMuleSoft.isFromTrigger = true; //INTEG_ISSUE_FIX_SS
            new ReceiptAllocationTriggerHandler().run('ReceiptAllocation__c');
            CalloutToMuleSoft.isFromTrigger = false; //INTEG_ISSUE_FIX_SS
        }
    } 
    catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'ReceiptAllocationTrigger','ReceiptAllocationTriggerHandler','')); throw e; }
}