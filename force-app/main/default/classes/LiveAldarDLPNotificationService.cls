public without sharing class LiveAldarDLPNotificationService {

    // Get details from Flow for notification
    @InvocableMethod(label='Send Customer Notification')
    public static void flowNotification(List<FlowInputParamsWrapper> inputParameters) {
        
        //System.debug('Notification>>>' + inputParameters);

        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            notificationBody(inputParameter);
        }
    }

    // Building notification body for API callout
    public static void notificationBody(FlowInputParamsWrapper inputParameter) {
        String requestBody = prepareNotificationBody(inputParameter);
        System.enqueueJob(new CustomerNotificationQueueable(requestBody));
        // calloutFutureService(requestBody);
    }
    
    // Building notification body for API callout
    public static string prepareNotificationBody(FlowInputParamsWrapper inputParameter) {
        Map<String, Object> notificationBodyMap = new Map<String, Object>();

        Map<String, Object> notificationDataMap = new Map<String, Object>();
        notificationDataMap.put('title', inputParameter.notificationTitle);
        notificationDataMap.put('body', inputParameter.notificationBody);
        notificationDataMap.put('arTitle', inputParameter.notificationARTitle);
        notificationDataMap.put('arBody', inputParameter.notificationARBody);
        
        notificationDataMap.put('click_action', CustomerAPIConstants.NOTIFICATION_CLICK_ACTION);

        notificationBodyMap.put('user_id', inputParameter.accountEmail);
        notificationBodyMap.put('device_id', '');

        notificationBodyMap.put('type', String.isNotBlank(inputParameter.type) ? inputParameter.type : ''); // Profile of Financial Statement or Property Journey or Service Request
        notificationBodyMap.put('subType', String.isNotBlank(inputParameter.subType) ? inputParameter.subType : ''); // Payment Due, Upcoming
        notificationBodyMap.put('recordId', String.isNotBlank(inputParameter.recordId) ? inputParameter.recordId : ''); // a2A8d000000LdlZEASSf Record Id
        notificationBodyMap.put('importantNotification', String.isNotBlank(inputParameter.importantNotification) ? inputParameter.importantNotification : 'no'); // yes or no
        
        notificationBodyMap.put('notification_data', notificationDataMap);
        System.debug('Chirag'+notificationBodyMap);
        String requestBody = JSON.serialize(notificationBodyMap);
        return requestBody;
    }
    
    /*/public static void enqueueNotification(List<FlowInputParamsWrapper> inputParameters) {
        System.debug('Bulk Notification>>>' + inputParameters);
         list<string> params = new list<string>();
        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            params.add(prepareNotificationBody(inputParameter));
        }
        if(params.size()>0){
            System.enqueueJob(new CustomerNotificationQueueableBulk(params));
        }
    }*/
     
    public class FlowInputParamsWrapper {
        @InvocableVariable(label='Account Id'       required=true)
        public String accountId;

        @InvocableVariable(label='Account Email'       required=true)
        public String accountEmail;
        
        @InvocableVariable(label='Notification Title'       required=true)
        public String notificationTitle;
        
        @InvocableVariable(label='Notification Body'       required=true)
        public String notificationBody;
        
        @InvocableVariable(label='Notification Arabic Title')
        public String notificationARTitle;
        
        @InvocableVariable(label='Notification Arabic Body')
        public String notificationARBody;
        
        @InvocableVariable(label='Type')
        public String type;
        
        @InvocableVariable(label='Sub Type')
        public String subType;
        
        @InvocableVariable(label='Record Id')
        public String recordId;
        
        @InvocableVariable(label='Important Notification - "yes" or "no"')
        public String importantNotification;
    }
}