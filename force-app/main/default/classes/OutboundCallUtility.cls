public with sharing class OutboundCallUtility {
    public static string getAccessToken(){
        APISetting__mdt  outboundLoginSetting = Utilities.getServiceDetails(Constants.OUTBOUND_LOGIN);
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration = (Map<String,String>)JSON.deserialize(outboundLoginSetting.Headers__c, Map<String,String>.class);
        String endPointURL = outboundLoginSetting.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = outboundLoginSetting.ProductionURL__c ; 
        
        }
        endPointURL = endPointURL.replace('{client_id}',outboundLoginSetting.APIKey__c).replace('{client_secret}',outboundLoginSetting.SecretKey__c);
        HttpResponse response  = callOutboundAPI(headerConfiguration , endPointURL , outboundLoginSetting.Method__c, '');
        boolean success = (response!=null && response.getStatusCode() == 200);
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            return String.ValueOf(responseMap.get('access_token'));
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','getAccessToken',Constants.OUTBOUND_LOGIN,null,response.getBody(),null));
        }
        return null;
    }

    public static map<string,string> getContactLists(string token){
        map<string,string> mapToReturn = new map<string,string>();
        APISetting__mdt  outboundContactListSetting = Utilities.getServiceDetails(Constants.OUTBOUND_CONTACTLIST);
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration =new Map<String,String>();
        headerConfiguration.put('Authorization','Bearer '+token);
        String endPointURL = outboundContactListSetting.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = outboundContactListSetting.ProductionURL__c ; 
        
        }
        HttpResponse response  = callOutboundAPI(headerConfiguration , endPointURL , outboundContactListSetting.Method__c, '');
        boolean success = (response!=null && response.getStatusCode() == 200);
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            for(Object listRecord : (list<Object>)responseMap.get('entities')){
                map<string,object> listEntry = (map<String,object>) listRecord;
                mapToReturn.put( String.ValueOf(listEntry.get('name')), String.ValueOf(listEntry.get('id')));
            }
            system.debug('Contact List:'+ response.getBody());
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','getContactLists',Constants.OUTBOUND_CONTACTLIST,null,response.getBody(),null));
        }
        return mapToReturn;
    }

    public static boolean initiateOutboundCall(string token, string contactListId, String JSONBody){
        APISetting__mdt  outboundCallSetting = Utilities.getServiceDetails(Constants.OUTBOUND_CALL);
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration =new Map<String,String>();
        headerConfiguration.put('Authorization','Bearer '+token);
        headerConfiguration.put('Content-Type','application/json');
        
        String endPointURL = outboundCallSetting.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = outboundCallSetting.ProductionURL__c ; 
        
        }
        endPointURL = endPointURL.replace('{contactListId}',contactListId);

        HttpResponse response  = callOutboundAPI(headerConfiguration , endPointURL , outboundCallSetting.Method__c, JSONBody);
        boolean success = (response!=null && response.getStatusCode() == 200);
        if(success){
            System.debug('Response Success Body-->'+response.getBody());
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','initiateOutboundCall',Constants.OUTBOUND_LOGIN,null,JSONBody,null));
            return true;
        }else{
            System.debug('Response Failure Body-->'+response.getBody());
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','initiateOutboundCall',Constants.OUTBOUND_LOGIN,null,response.getBody(),null));
        }
        return false;
    }

    public static HttpResponse callOutboundAPI(Map<String,String> headerConfiguration, String endPointURL, String method, String JSONBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        } 
        request.setEndpoint(endPointURL);
        request.setMethod(method);
        if(JSONBody!=null && JSONBody!=''){
            request.setBody(JSONBody);
            //LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','initiateOutboundCall',Constants.OUTBOUND_LOGIN,null,JSONBody,null));
        }
        request.setTimeout(120000);
        return http.send(request);
    }

    @AuraEnabled
    public static string getAccessTokenforWhatsapp(){
        APISetting__mdt  outboundLoginSetting = Utilities.getServiceDetails('GenesysWhatsapp');
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration = (Map<String,String>)JSON.deserialize(outboundLoginSetting.Headers__c, Map<String,String>.class);
        String endPointURL = outboundLoginSetting.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = outboundLoginSetting.ProductionURL__c ; 
        
        }
        endPointURL = endPointURL.replace('{client_id}',outboundLoginSetting.APIKey__c).replace('{client_secret}',outboundLoginSetting.SecretKey__c);
        HttpResponse response  = callOutboundAPI(headerConfiguration , endPointURL , outboundLoginSetting.Method__c, '');
        boolean success = (response!=null && response.getStatusCode() == 200);
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            return String.ValueOf(responseMap.get('access_token'));
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','getAccessToken',Constants.OUTBOUND_LOGIN,null,response.getBody(),null));
        }
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static boolean initiateWhatsapp(string token, String flowid, string agentEmail, string customerMob, String customerLang){
        APISetting__mdt  outboundCallSetting = Utilities.getServiceDetails('GenesysWhatsappOutbound');
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration =new Map<String,String>();
        headerConfiguration.put('Authorization','Bearer '+token);
        headerConfiguration.put('Content-Type','application/json');
        System.debug('Header body-->'+headerConfiguration);
        System.debug('agenctemail-->'+agentEmail);
        String endPointURL = outboundCallSetting.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = outboundCallSetting.ProductionURL__c ; 
        
        }
        Map<String,Object> requestBody = new Map<String,Object>();
        requestBody.put('flowId',flowid);
        Map<String,String> innerBody = new Map<String,String>();
        innerBody.put('Flow.agentEmail',agentEmail);
        //innerBody.put('Flow.agentEmail','snasr@aldar.com.sit');
        innerBody.put('Flow.customerNumber',customerMob);
        //innerBody.put('Flow.Language','ar');
        innerBody.put('Flow.Language',customerLang);
        requestBody.put('inputData',innerBody);
        System.debug('Request body-->'+JSON.serialize(requestBody));
        //endPointURL = endPointURL.replace('{contactListId}',contactListId);

        HttpResponse response  = callOutboundAPI(headerConfiguration , endPointURL , outboundCallSetting.Method__c, JSON.serialize(requestBody));
        boolean success = (response!=null && response.getStatusCode() == 200);
        if(success){
            System.debug('Response Success Body-->'+response.getBody());
            return true;
        }else{
            System.debug('Response Failure Body-->'+response.getBody());
            LoggerService.save(LoggerService.addApexServiceCalls('OutboundCallUtility','initiateOutboundCall',Constants.OUTBOUND_LOGIN,null,response.getBody(),null));
        }
        return false;
    }
}