public with sharing class CustomerNotificationQueueable implements Queueable, Database.AllowsCallouts {
    
    public String requestBody;

    public CustomerNotificationQueueable(String requestBody) {
        this.requestBody = requestBody;
    }

    public void execute(QueueableContext context) {
        sendNotification(this.requestBody);
    }

    public static void sendNotification(String requestBody) {
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
}