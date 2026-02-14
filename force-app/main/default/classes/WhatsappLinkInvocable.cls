public without sharing class WhatsappLinkInvocable {
     @InvocableMethod(label='Send WhatsApp Link')
    public static void flowWhatsApp(List<FlowInputParamsWrapper> inputParameters) {
        
        System.debug('Notification>>>' + inputParameters);

        for (FlowInputParamsWrapper inputParameter: inputParameters) {
            notificationBody(inputParameter);
        }
    }

    // Building notification body for API callout
    public static void notificationBody(FlowInputParamsWrapper inputParameter) {
        Map<String, Object> notificationBodyMap = new Map<String, Object>();		
		system.debug('AttributeValue5'+inputParameter.AttributeValue5);
        WatsAppLinkGenesys__mdt whatsappgen = WatsAppLinkGenesys__mdt.getInstance('FastTrack');
		WatsAppLinkGenesys__mdt NOCwhatsappgen = WatsAppLinkGenesys__mdt.getInstance('NOC');       
        Map<String, Object> notificationDataMap = new Map<String, Object>();
        notificationDataMap.put('Flow.CustomerName',inputParameter.CustomerName);
        notificationDataMap.put('Flow.ProjectName',inputParameter.ProjectName);
		if(inputParameter.AttributeValue5=='NOC'){
			notificationDataMap.put('Flow.HSMTemplateId',NOCwhatsappgen.HSMTemplateId__c);
        }
        else{
        	notificationDataMap.put('Flow.HSMTemplateId',whatsappgen.HSMTemplateId__c);
        }
        notificationDataMap.put('Flow.MobileNumber',inputParameter.MobileNumber);
        notificationDataMap.put('Flow.SalesManager',inputParameter.SalesManager);
        notificationDataMap.put('Flow.LeadNumber',inputParameter.LeadNumber);
        notificationDataMap.put('Flow.MessageType',inputParameter.MessageType);
        notificationDataMap.put('Flow.AttributeName1',inputParameter.AttributeName1);
        notificationDataMap.put('Flow.AttributeValue1',inputParameter.AttributeValue1);
        notificationDataMap.put('Flow.AttributeName2',inputParameter.AttributeName2);
        notificationDataMap.put('Flow.AttributeValue2',inputParameter.AttributeValue2);
        notificationDataMap.put('Flow.AttributeName3',inputParameter.AttributeName3);
        notificationDataMap.put('Flow.AttributeValue3',inputParameter.AttributeValue3);
        notificationDataMap.put('Flow.AttributeName4',inputParameter.AttributeName4);
        notificationDataMap.put('Flow.AttributeValue4',inputParameter.AttributeValue4);
        notificationDataMap.put('Flow.AttributeName5',inputParameter.AttributeName5);
        notificationDataMap.put('Flow.AttributeValue5',inputParameter.AttributeValue5);

		
        notificationBodyMap.put('flowId', '');
        notificationBodyMap.put('name', ''); 
		if(inputParameter.AttributeValue5=='NOC'){
			notificationBodyMap.put('name','livealdar_noc_notification');
			notificationBodyMap.put('flowId', '9941d591-26df-470c-860a-bb72bcdd7106');
        }
        
        notificationBodyMap.put('inputData', notificationDataMap);

        String requestBody = JSON.serialize(notificationBodyMap);

        system.debug('requestbodywhatsapp::'+requestBody);
         calloutFutureService(requestBody);
    }
    @future(callout = true)
    public static void calloutFutureService(String requestBody) {
        System.debug('calloutFutureService invoked');
        String muleRes = '';
        try{
            //---- Fetch mulesoft URLs
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(CustomerAPIConstants.WHATSAPP_LINK_GENESYS);
          
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
            Logger__c log = LoggerService.createApexLog(ex, '', 'WhatsAppApiLink', 'calloutFutureService');
            log.Message__c = requestBody;
            log.ResponseMessage__c = muleRes;
            log = LoggerService.saveAndReturnLogger(log);
            System.debug('Exception lgs.Id>>>' + log.Id);
        } 
    }

     public class FlowInputParamsWrapper {
        @InvocableVariable(label='CustomerName')
        public String CustomerName;

        @InvocableVariable(label='ProjectName')
        public String ProjectName;
        
        @InvocableVariable(label='HSMTemplateId')
        public String HSMTemplateId;
        
        @InvocableVariable(label='MobileNumber')
        public String MobileNumber;
        
        @InvocableVariable(label='SalesManager')
        public String SalesManager;
        
        @InvocableVariable(label='LeadNumber')
        public String LeadNumber;
        @InvocableVariable(label='MessageType')
        public String MessageType;
        @InvocableVariable(label='AttributeName1')
        public String AttributeName1;
        @InvocableVariable(label='AttributeValue1')
        public String AttributeValue1;
        @InvocableVariable(label='AttributeName2')
        public String AttributeName2;
        @InvocableVariable(label='AttributeValue2')
        public String AttributeValue2;
        @InvocableVariable(label='AttributeName3')
        public String AttributeName3;
        @InvocableVariable(label='AttributeValue3')
        public String AttributeValue3;
        @InvocableVariable(label='AttributeName4')
        public String AttributeName4;
        @InvocableVariable(label='AttributeValue4')
        public String AttributeValue4;
        @InvocableVariable(label='AttributeName5')
        public String AttributeName5;
        @InvocableVariable(label='AttributeValue5')
        public String AttributeValue5;
    }

    

    

    
}