/*****************************************************************************************************************
* Name               : BrokerAppBellNotificationBatch                                                        
* Description        : Batch class to send custom notifications to all the users of Broker Portal
* Created By         : Tharun    
* Created Date		 : 15 Jan 2024
******************************************************************************************************************/
global class BrokerAppBellNotificationBatch implements Database.Batchable<sObject>
{
    Set<Id> banReceivedIds = new Set<Id>();
    Id customNotificaitonId = Label.BROKERAPP_NOTIFICATION_ID;
    String NOTIFICATION_TITLE;
    String NOTIFICATION_MESSAGE;
    String NOTIFICATION_ID;
    public BrokerAppBellNotificationBatch(Set<Id> receivedCommRecords){
        this.banReceivedIds = receivedCommRecords;
        List<BrokerAppNotification__c> banList = [SELECT 
                                                  Id, 
                                                  Title__c, 
                                                  ShortMessage__c, 
                                                  Status__c 
                                                  FROM BrokerAppNotification__c 
                                                  WHERE Id IN : banReceivedIds LIMIT 1];
        NOTIFICATION_TITLE = banList[0].Title__c;
        NOTIFICATION_MESSAGE = banList[0].ShortMessage__c;
        NOTIFICATION_ID = banList[0].Id;
    }
    global List<User> start(Database.BatchableContext bc) {
        List<User> userList = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Partner Community Login'
                               AND (ProfileName__c = 'Agency Admin Login' OR ProfileName__c = 'Agency User Login')
                               AND IsActive = true
                               AND Account.AgencyStatus__c = 'Active' 
                               AND Contact.AgentStatus__c = 'Active'];
        return userList;
    }
    global void execute(Database.BatchableContext bc, List<User> scope)
    {
        Set<Id> userIds = (new Map<Id, User>(scope).keySet());
        Set<String> idStrs = (Set<String>)JSON.deserialize(JSON.serialize(userIds), Set<String>.class);
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set the contents for the notification
        notification.setTitle(NOTIFICATION_TITLE);
        notification.setBody(NOTIFICATION_MESSAGE);
        
        // Set the notification type and target
        notification.setNotificationTypeId(customNotificaitonId);
        notification.setTargetId(NOTIFICATION_ID);
        
        // Actually send the notification
        try {
            notification.send(idStrs);
        }
        catch (Exception e){
            System.debug('Problem sending notification: ' + e.getMessage());
            LoggerService.save(LoggerService.createApexLog(e,'execute','BrokerAppBellNotificationBatch','execute'));
        }
    }
    
    global void finish(Database.BatchableContext bc)
    {
        System.debug('Finish Method Executed');
    }
    
}