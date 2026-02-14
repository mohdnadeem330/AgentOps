public without sharing class SendGridProjectEmailController {
    @InvocableMethod(label='SendGrid Project Email')
    public static void flowNotification(List<FlowInputParamsWrapper> inputParameters) {
        
        System.debug('Notification>>>' + inputParameters);

        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            notificationBody(inputParameter);
        }
    }
    
    public static void notificationBody(FlowInputParamsWrapper inputParameter) {
        List<SendGridEmail__mdt> sendGridMail = [SELECT Id,MasterLabel,Factsheet_Link__c,Property_Image__c,ArabicProjectName__c FROM SendGridEmail__mdt WHERE MasterLabel =: inputParameter.ProjectName AND IsActive__c = true];
        if(sendGridMail.size() >0){
            String requestBodyJson = '{"bcc": "","cc": "","recipient_email": "'+inputParameter.EmailId+'","type": "tpl_fs_1","language": "en","customer_name": "'+inputParameter.customerName+'","property_name_en": "'+inputParameter.ProjectName+'","property_name_ar": "'+sendGridMail[0].ArabicProjectName__c+'","factsheet_link":"'+sendGridMail[0].Factsheet_Link__c+'","property_image": "'+sendGridMail[0].Property_Image__c+'"}';
            sendProjectEmail(requestBodyJson);
            
        }
    }
     @future(callout = true)
     public static void sendProjectEmail(String requestBody) {
        try{
        //GET HEADER MAP AND ENDPOINT FROM CONFIGURATION
        APISetting__mdt  sendGridAPI = Utilities.getServiceDetails(SendGridIntegrationUtilities.SENDGRID_PAYMENT_REMINDER);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = sendGridAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = sendGridAPI.ProductionURL__c ; 
        }
        Map<String,String> headersMap = (Map<String,String>)JSON.deserialize(sendGridAPI.Headers__c, Map<String,String>.class);

        // Create an HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPointURL);
        request.setMethod(sendGridAPI.Method__c);
        for(String headerName : headersMap.keySet()){
            request.setHeader(headerName, headersMap.get(headerName));
        }
        request.setBody(requestBody);
        request.setTimeout(120000);
        system.debug('requestBodyJson' + requestBody);
        // Create an HTTP instance to send the request
        Http http = new Http();
        HttpResponse response;


        response = http.send(request);
        System.debug(response.getBody());
        }catch(Exception ex) {
            Logger__c log = LoggerService.createApexLog(ex, '', 'SendGrid FactSheet', 'sendProjectEmail');
            log.Message__c = requestBody;
            log.ResponseMessage__c = '';
            log = LoggerService.saveAndReturnLogger(log);
            System.debug('Exception lgs.Id>>>' + log.Id);
        } 
    }
    public class FlowInputParamsWrapper {
        @InvocableVariable(label='Project Name'       required=true)
        public String ProjectName;

        @InvocableVariable(label='Email'       required=true)
        public String EmailId;

        @InvocableVariable(label='Customer Name'       required=true)
        public String customerName;
    }
}