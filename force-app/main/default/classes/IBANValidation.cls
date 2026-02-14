public with sharing class IBANValidation {
    
    @AuraEnabled(cacheable=true)
    public static boolean getValidateIbanWithAura(String ibanNumber) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        APISetting__mdt  IBAN = Utilities.getServiceDetails(Constants.IBAN);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = IBAN.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = IBAN.ProductionURL__c ; 
        }
        
        request.setEndpoint(endPointURL + ibanNumber);
        request.setMethod(IBAN.Method__c);
        
        HttpResponse response = http.send(request);
                
        JSONParser parser = JSON.createParser(response.getBody());
        
        String valid='';
        boolean isValid = false;

        		
		while(parser.nextToken() != null){

            if(Constants.VALID.equalsIgnoreCase(parser.getText())){
                
                parser.nextToken();
                valid = parser.getText();
                isValid = true;
                
                if(!'true'.equalsIgnoreCase(valid)){
	                    isValid = false;
                }
                break;
            }
        }
        return isValid;
    }

}