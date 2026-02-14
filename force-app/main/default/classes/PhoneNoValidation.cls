public class PhoneNoValidation {

    @InvocableMethod
    public static List<boolean> validatePhoneNo(List<String> phoneNo) {
        boolean isValid = true;

    /*    phoneNo[0] = phoneNo[0].replaceAll('(\\s+)', '').replace('+','');
        if(phoneNo[0].left(2) == '01'){
            phoneNo[0]=phoneNo[0].right(phoneNo[0].length()-1);
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        //---- Get Phone API information from the API Settings
        APISetting__mdt  phoneAPI = Utilities.getServiceDetails(Constants.PHONE);
        
        //---- Check if the instance is Sandbox or Production
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = phoneAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = phoneAPI.ProductionURL__c ; 
        } 
        
        request.setEndpoint(endPointURL + 'Key=' + phoneAPI.APIKey__c + '&Phone='+phoneNo[0]);
        request.setMethod(phoneAPI.Method__c);
        
        HttpResponse response = http.send(request);
                
        JSONParser parser = JSON.createParser(response.getBody());
        
        String isValidPhoneNo='';
        boolean isValid = false;

                
        while(parser.nextToken() != null){

            if(Constants.IS_VALID.equals(parser.getText())){
                
                parser.nextToken();
                isValidPhoneNo = parser.getText();
                
                if(Constants.YES.equalsIgnoreCase(isValidPhoneNo)){
                        isValid = true;
                }
                break;
            }
        }*/
        return new List<boolean> {isValid};
    }

    @AuraEnabled(cacheable=true)
    public static boolean getValidatePhoneNoWithAura(String phoneNo) {

        boolean isValid =  validatePhoneNo(new List<String> {phoneNo})[0];
        return isValid;
    }
}