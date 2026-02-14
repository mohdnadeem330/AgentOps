public without sharing class CustomerNotificationWebService {

    // Get details from Flow for notification
    @InvocableMethod(label='Send Customer Notification')
    public static void flowNotification(List<FlowInputParamsWrapper> inputParameters) {
        
        System.debug('Notification>>>' + inputParameters);

        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            notificationBody(inputParameter);
        }
    }

    // Building notification body for API callout
    public static void notificationBody(FlowInputParamsWrapper inputParameter) {
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

        String requestBody = JSON.serialize(notificationBodyMap);

        calloutFutureService(requestBody);
    }

    // Do callout for notification and reminder notification to Customer Portal and App
    @future(callout = true)
    public static void calloutFutureService(String requestBody) {
        System.debug('calloutFutureService invoked');
        String muleRes = '';
        try{
            //---- Fetch mulesoft URLs
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(CustomerAPIConstants.CUSTOMER_NOTIFICATION_INTEGRATION);
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            if (!org.IsSandbox) {
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('client_secret', mulesoftAPI.APIKey__c);
            request.setHeader('client_id', mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            System.debug('**Request Body**' + requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            muleRes = response.getBody();
           
            System.debug('**Response Body**' + muleRes);
        } catch(Exception ex) {
            Logger__c log = LoggerService.createApexLog(ex, '', 'CustomerNotificationWebService', 'calloutFutureService');
            log.Message__c = requestBody;
            log.ResponseMessage__c = muleRes;
            log = LoggerService.saveAndReturnLogger(log);
            System.debug('Exception lgs.Id>>>' + log.Id);
        } 
    }

    public class FlowInputParamsWrapper {
        @InvocableVariable(label='Account Id'       required=true)
        public String accountId;

        @InvocableVariable(label='Account Email'       required=true)
        public String accountEmail;
        
        @InvocableVariable(label='Notification Title'       required=true)
        public String notificationTitle;
        
        @InvocableVariable(label='Notification Body'       required=true)
        public String notificationBody;
        
        @InvocableVariable(label='Notification Arabic Title'       required=true)
        public String notificationARTitle;
        
        @InvocableVariable(label='Notification Arabic Body'       required=true)
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