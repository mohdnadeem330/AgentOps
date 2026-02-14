trigger BookingMemoTrigger on BookingMemo__c (after update) {
    try {    
        new BookingMemoTriggerHandler().run('BookingMemo__c');
    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'BookingMemoTrigger','BookingMemoTriggerHandler',''));
        throw e;
    } 
}