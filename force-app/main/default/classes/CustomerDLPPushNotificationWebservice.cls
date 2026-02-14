public class CustomerDLPPushNotificationWebservice {
    // Get details from Flow for notification
    @InvocableMethod(label='Send Customer Push Notification')
    public static void flowNotification(List<FlowInputParamsWrapper> inputParameters) {
        
        System.debug('Notification>>>' + inputParameters);
        
        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            notificationBody(inputParameter);
        }
    }
    
    // Building notification body for API callout
    public static void notificationBody(FlowInputParamsWrapper inputParameter) {
        
        NotificationWrapper notify = new NotificationWrapper();
        notify.notificationData = new NotificationDetails();
        
        notify.userId = String.isNotBlank(inputParameter.notificationUserId) ? inputParameter.notificationUserId : '';
        notify.userName = String.isNotBlank(inputParameter.notificationUserName) ? inputParameter.notificationUserName : '';
        notify.userEmail = String.isNotBlank(inputParameter.notificationUserEmail) ? inputParameter.notificationUserEmail : '';
        notify.messageType = String.isNotBlank(inputParameter.notificationMessageType) ? inputParameter.notificationMessageType : '';
        notify.subAppType = String.isNotBlank(inputParameter.notificationSubAppType) ? inputParameter.notificationSubAppType : '';
        
        notify.notificationData.click_action = String.isNotBlank(inputParameter.notificationClickAction) ? inputParameter.notificationClickAction : '';
        notify.notificationData.arBody = String.isNotBlank(inputParameter.notificationARBody) ? inputParameter.notificationARBody : '';
        notify.notificationData.arTitle = String.isNotBlank(inputParameter.notificationARTitle)  ? inputParameter.notificationARTitle : '';
        notify.notificationData.body = String.isNotBlank(inputParameter.notificationBody)  ? inputParameter.notificationBody : '';
        notify.notificationData.title = String.isNotBlank(inputParameter.notificationTitle)  ? inputParameter.notificationTitle : '';
        
        notify.notificationType = String.isNotBlank(inputParameter.notificationType) ? inputParameter.notificationType : '';
        notify.functionalType = String.isNotBlank(inputParameter.notificationFunctionalType) ? inputParameter.notificationFunctionalType : '';
        notify.functionalSubType = String.isNotBlank(inputParameter.notificationFunctionalSubType) ? inputParameter.notificationFunctionalSubType : '';
        notify.functionalRecordId = String.isNotBlank(inputParameter.notificationFunctionalRecordId) ? inputParameter.notificationFunctionalRecordId : '';
        notify.functionalUnitName = String.isNotBlank(inputParameter.notificationFunctionalUnitName) ? inputParameter.notificationFunctionalUnitName : '';
        
        String requestBody = JSON.serialize(notify);
        System.debug('requestBody : ' + requestBody);
        if(String.isNotBlank(requestBody)){
            calloutFutureService(requestBody);
        }
    }
    
    // Do callout for notification and reminder notification to Customer Portal and App
    // @future(callout = true)
    public static void calloutFutureService(String requestBody) {
        System.debug('calloutFutureService invoked');
        String muleRes = '';
        try{
            //---- Fetch mulesoft URLs
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(CustomerAPIConstants.CUSTOMER_PUSH_NOTIFICATION_INTEGRATION);
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
        
        @InvocableVariable(label='User Id')  // Account's PersonEmail
        public String notificationUserId;
        
        @InvocableVariable(label='User Name' )  // Account's Name
        public String notificationUserName;
        
        @InvocableVariable(label='User Email' )   // Account's PersonEmail Registerd in Live Aldar
        public String notificationUserEmail;
        
        @InvocableVariable(label='Message Type') // Transactional / Promotional
        public String notificationMessageType;
        
        @InvocableVariable(label='Sub App Type')  // PRO / EDU / DAR
        public String notificationSubAppType;
        
        @InvocableVariable(label='Click Action' ) // fcm.ACTION.NOTIF
        public String notificationClickAction;
        
        @InvocableVariable(label='Notification Arabic Body' )  // Arabic Body
        public String notificationARBody;
        
        @InvocableVariable(label='Notification Arabic Title' ) // Arabic Title
        public String notificationARTitle;
        
        @InvocableVariable(label='Notification Body' ) // Arabic & English Body
        public String notificationBody;
        
        @InvocableVariable(label='Notification Title' ) // English Title
        public String notificationTitle;
        
        @InvocableVariable(label='Notification Type') // English Title
        public String notificationType;
        
        @InvocableVariable(label='Functional Type')  // Property Journey / Digital Sales / Digital SPA
        public String notificationFunctionalType;
        
        @InvocableVariable(label='Functional Sub Type') // Home Orientation / Snagging / Desnaggging
        public String notificationFunctionalSubType;
        
        @InvocableVariable(label='Functional Record Id') // SalesOrder's Id
        public String notificationFunctionalRecordId; 
        
        @InvocableVariable(label='Functional Unit Name') // Unit's Name
        public String notificationFunctionalUnitName;
        
    }
    
    public class NotificationWrapper {
        
        public string userId;
        public string userName;
        public string userEmail;
        public string messageType;
        public string subAppType;
        public NotificationDetails notificationData;
        public string notificationType;
        public string functionalType;
        public string functionalSubType;
        public string functionalRecordId;
        public string functionalUnitName;
    }
    
    public class NotificationDetails {
        
        public string click_action;
        public string arBody;
        public string arTitle;
        public string body;
        public string title;
    }
}