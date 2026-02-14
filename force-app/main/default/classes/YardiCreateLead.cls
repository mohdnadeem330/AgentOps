public with sharing class YardiCreateLead {

    private YardiCreateLeadRequestWrapper yardiRequest;
    
    @InvocableMethod(callout=true)
    public static void LeadImport(List<Lead> leadToImport) {
        
        APISetting__mdt  leadImportAPI = Utilities.getServiceDetails(Constants.LEAD_IMPORT);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = leadImportAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = leadImportAPI.ProductionURL__c ; 
        }

        Map<String,String> headers = (Map<String,String>)JSON.deserialize(leadImportAPI.Headers__c, Map<String,String>.class);

        Blob authorizationHeader = Blob.valueOf(leadImportAPI.UserName__c + ':' + leadImportAPI.Password__c);
        String authorizationHeaderString = 'Basic ' + EncodingUtil.base64Encode(authorizationHeader);
        headers.put('Authorization',authorizationHeaderString);

        YardiCreateLeadRequestWrapper requestBody = new YardiCreateLeadRequestWrapper(leadToImport[0]);
        String reqBody = json.serialize(requestBody);

        try{  
            callout(reqBody, headers, endPointURL, leadImportAPI.Method__c, leadToImport[0].Id, leadToImport[0].OwnerId);
        } catch(Exception e){
                system.debug(e);
        }
    }


    @future(callout = true)
    public static void callout(String requestBody, Map<String,String> headers, String endPointURL, String httpMethod, Id leadId, Id ownerId){

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        for(String headerName : headers.keySet()){
            request.setHeader(headerName, headers.get(headerName));
        }

        request.setEndpoint(endPointURL);
        request.setMethod(httpMethod);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);
        JSONParser parser = JSON.createParser(response.getBody());
        
        String Status = '';
        String Message = '';
        boolean isSuccess = false;

		while(parser.nextToken() != null){

            if(Constants.STATUS.equals(parser.getText())){
                
                parser.nextToken();
                Status = parser.getText();
                
                if(Constants.YARDI_SUCCESS_STATUS.equalsIgnoreCase(Status)){
                    isSuccess = true;
                }
            }
        }
        
        if(!isSuccess){
            LoggerService.save(LoggerService.addApexServiceCalls('LeadImport','YardiCreateLead','callout','requestBody: '+requestBody+' headers: '+headers,response.getBody(),leadId));
        } else{
            UtilitiesWithoutSharing.changeSentToYardiField(leadId);
        }
    }
}