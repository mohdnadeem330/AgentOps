/*****************************************************************************************************************
* Name               : BrokerAppNotificationTrigger                                                        
* Description        : Trigger class for BrokerAppNotificationTrigger custom object
* Created By         : Tharun
* Created Date		 : 15 Jan 2024
******************************************************************************************************************/
trigger BrokerAppNotificationTrigger on BrokerAppNotification__c (after update) {
    try {
        BrokerAppNotificationHandler obj;
        obj = new BrokerAppNotificationHandler();
        obj.run('BrokerAppNotification');
    } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'BrokerAppNotificationTrigger','BrokerAppNotificationHandler',''));throw e; } 
}