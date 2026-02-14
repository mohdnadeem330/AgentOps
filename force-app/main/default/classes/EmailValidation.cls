public with sharing class EmailValidation {

    @InvocableMethod(callout=true)
    public static List<boolean> validateEmail(List<String> email) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();
                boolean isValid = true;

     /*   APISetting__mdt  emailAPI = Utilities.getServiceDetails(Constants.EMAIL);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = emailAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = emailAPI.ProductionURL__c ; 
        }
        
        request.setEndpoint(endPointURL + 'Key=' + emailAPI.APIKey__c + '&Email='+email[0]);
        request.setMethod(emailAPI.Method__c);
        
        HttpResponse response = http.send(request);
                
        JSONParser parser = JSON.createParser(response.getBody());
        
        String responseCode='';

        		
		while(parser.nextToken() != null){

            if(Constants.RESPONSE_CODE.equals(parser.getText())){
                
                parser.nextToken();
                responseCode = parser.getText();
                
                if(Constants.INVALID.equalsIgnoreCase(responseCode)){
	                    isValid = false;
                }
                break;
            }
        }*/
        return new List<boolean> {isValid};
    }

    @AuraEnabled(cacheable=true)
    public static boolean getValidateEmailWithAura(String email) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();
                boolean isValid = true;

/*        APISetting__mdt  emailAPI = Utilities.getServiceDetails(Constants.EMAIL);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = emailAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = emailAPI.ProductionURL__c ; 
        }
        
        request.setEndpoint(endPointURL + 'Key=' + emailAPI.APIKey__c + '&Email='+email+'&timeout=60000');
        request.setMethod(emailAPI.Method__c);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
                
        system.debug(response.getBody());

        JSONParser parser = JSON.createParser(response.getBody());
        
        String responseCode='';
        boolean isValid = false;

        		
		while(parser.nextToken() != null){

            if(Constants.RESPONSE_CODE.equals(parser.getText())){
                

                parser.nextToken();
                responseCode = parser.getText();
                isValid = true;

                system.debug('responseCode: '+responseCode);

                
                if(Constants.INVALID.equalsIgnoreCase(responseCode)){
	                    isValid = false;
                }
                break;
            }
        }*/
        return isValid;
    }
}