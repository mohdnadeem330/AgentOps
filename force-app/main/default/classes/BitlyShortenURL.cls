global with sharing class BitlyShortenURL {
    global static String shortenURLHelper(String actualURL){
        APISetting__mdt  bitlyAPI = Utilities.getServiceDetails(Constants.BITLY);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = bitlyAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = bitlyAPI.ProductionURL__c ; 
        }
        
        Map<String,String> headers = (Map<String,String>)JSON.deserialize(bitlyAPI.Headers__c, Map<String,String>.class);
        
        RequestWrapper requestBody = new RequestWrapper(actualURL);
        String reqBody = json.serialize(requestBody);
        
        try{  
           return calloutWithoutSMS(reqBody, headers, endPointURL, bitlyAPI.Method__c,  org.IsSandbox);
            
        } catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'BitlyShortenURL','shortenURL',''));
            system.debug(e);
            return null;
        }
    }
    
    public static String calloutWithoutSMS(String requestBody, Map<String,String> headers, String endPointURL, String httpMethod,boolean isSandbox){
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        for(String headerName : headers.keySet()){
            request.setHeader(headerName, headers.get(headerName));
        }
        
        request.setEndpoint(endPointURL);
        request.setMethod(httpMethod);
        request.setBody(requestBody);
        
        System.debug('requestBody: '+requestBody);
        
        HttpResponse response;
        if(test.isRunningTest()){
            response = new HttpResponse();
            response.setBody('{"message": "UNPROCESSABLE_ENTITY","resource": "bitlinks","description": "The JSON value provided is invalid."}');
        }else{
            response=http.send(request);
        }
        
        JSONParser parser = JSON.createParser(response.getBody());
        
        String shortenURL = '';
        
        System.debug('response: '+response.getBody());
        
        while(parser.nextToken() != null){
            
            if('link'.equals(parser.getText())){
                
                parser.nextToken();
                shortenURL = parser.getText();
            }
        }
        system.debug('shortenURL '+shortenURL);
        
        return shortenURL;
        
    }
    
    @InvocableMethod
    global static Void shortenURL(BitlyRequest[] bitlyRequest) {

        APISetting__mdt  bitlyAPI = Utilities.getServiceDetails(Constants.BITLY);
        Organization org = Utilities.getOrganizationDetails();
           
        String endPointURL = bitlyAPI.SandboxURL__c ;
           
        if(!org.IsSandbox){
            endPointURL = bitlyAPI.ProductionURL__c ; 
        }
   
        Map<String,String> headers = (Map<String,String>)JSON.deserialize(bitlyAPI.Headers__c, Map<String,String>.class);
        
        RequestWrapper requestBody = new RequestWrapper(bitlyRequest[0].url);
        String reqBody = json.serialize(requestBody);

        try{  
            callout(reqBody, headers, endPointURL, bitlyAPI.Method__c, bitlyRequest[0].destination, bitlyRequest[0].smsBody, 
            bitlyRequest[0].lead.Id, bitlyRequest[0].lead.OwnerId, org.IsSandbox);
            
        } catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'BitlyShortenURL','shortenURL',''));
            system.debug(e);
        }
    }

    @future(callout = true)
    public static void callout(String requestBody, Map<String,String> headers, String endPointURL, String httpMethod, String destination,
     String smsBody, Id leadId, Id ownerId, boolean isSandbox){

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        for(String headerName : headers.keySet()){
            request.setHeader(headerName, headers.get(headerName));
        }

        request.setEndpoint(endPointURL);
        request.setMethod(httpMethod);
        request.setBody(requestBody);

        System.debug('requestBody: '+requestBody);

        HttpResponse response;
        if(test.isRunningTest()){
            response = new HttpResponse();
            response.setBody('{"message": "UNPROCESSABLE_ENTITY","resource": "bitlinks","description": "The JSON value provided is invalid."}');
        }else{
            response=http.send(request);
        }
        
        JSONParser parser = JSON.createParser(response.getBody());
        
        String shortenURL = '';

        System.debug('response: '+response.getBody());

        while(parser.nextToken() != null){

            if('link'.equals(parser.getText())){
                
                parser.nextToken();
                shortenURL = parser.getText();
            }
        }
        
        if(shortenURL == null || String.isEmpty(shortenURL)){
            LoggerService.save(LoggerService.addApexServiceCalls('BitlyShortenURL','BitlyShortenURL','callout',requestBody,response.getBody(),null));
        } else{

            callSMSAPI(shortenURL, smsBody, destination, leadId, ownerId, isSandbox);
        }
    }

    public static void callSMSAPI(String shortenURL, String smsBody, String destination, String leadId, String ownerId, boolean isSandbox){

        APISetting__mdt  smsAPI = Utilities.getServiceDetails(Constants.SMS);
           
            String smsEndPointURL = smsAPI.SandboxURL__c ;
           
            if(!isSandbox){
                smsEndPointURL = smsAPI.ProductionURL__c ; 
            }

            smsBody += ' '+ shortenURL;

            System.debug('smsBody: '+smsBody);


            SmsNotificationAPI.nonFutureCallout(smsBody, destination, leadId, ownerId, smsEndPointURL, smsAPI.username__c,
             smsAPI.apiId__c, smsAPI.source__c, smsAPI.Method__c);
    }

    public class RequestWrapper {

        String domain = 'bit.ly';
        String long_url;

        RequestWrapper(String url){
            this.domain = 'bit.ly';
            this.long_url = url;
        }
    }

    global class BitlyRequest {

        @InvocableVariable(required=true)
        global String url;

        @InvocableVariable(required=true)
        global String destination;

        @InvocableVariable(required=true)
        global String smsBody;
        
        @InvocableVariable(required=true)
        global Lead lead;
    }
}