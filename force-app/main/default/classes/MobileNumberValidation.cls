public class MobileNumberValidation {

    //@InvocableMethod
    public static Map<String, String> validatePhoneNo(List<String> phoneNo)
    {
         phoneNo[0] = phoneNo[0].replaceAll('(\\s+)', '').replace('+','');
        if(phoneNo[0].left(2) == '01'){
            phoneNo[0]=phoneNo[0].right(phoneNo[0].length()-1);
    }
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        //---- Get Phone API information from the API Settings
        APISetting__mdt phoneAPI = Utilities.getServiceDetails(Constants.PHONE);

        //---- Check if the instance is Sandbox or Production
        Organization org = Utilities.getOrganizationDetails();

        String endPointURL = phoneAPI.SandboxURL__c;

        if (!org.IsSandbox) {
            endPointURL = phoneAPI.ProductionURL__c;
        }

        request.setEndpoint(endPointURL + 'Key=' + phoneAPI.APIKey__c + '&Phone='+phoneNo[0]);
        request.setMethod(phoneAPI.Method__c);
		system.debug('request '+request);
        HttpResponse response = http.send(request);

        JSONParser parser = JSON.createParser(response.getBody());
        system.debug('Response Code' + response.getBody());

        String countryPrefix = '';
        String nationalFormat = '';
         String isValid = '';
        

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) 
            {
                String fieldName = parser.getText();
                parser.nextToken();
                if ('CountryPrefix'.equals(fieldName)) {
                    countryPrefix = parser.getText();
                    system.debug('CountryPrefix: ' + countryPrefix);
                } 
                 if ('NationalFormat'.equals(fieldName)) {
                    nationalFormat = parser.getText();
                    system.debug('NationalFormat: ' + nationalFormat);
                }
                 if ('IsValid'.equals(fieldName)) 
                {
                    isValid = parser.getText();
                    system.debug('IsValid: ' + isValid);
                }
            }
        }

        Map<String, String> result = new Map<String, String>();
        result.put('CountryPrefix', countryPrefix);
        result.put('NationalFormat', nationalFormat);
        result.put('IsValid', isValid);

        return result;
    }
}