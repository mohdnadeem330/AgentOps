public class RemoveCountryCodeFromPhoneInvocable {
    
    public class Request {
        @InvocableVariable(required=true)
        public String countryCode;
        
        @InvocableVariable(required=true)
        public String fullPhoneNumber;
    }
    
    public class Response {
        @InvocableVariable
        public String cleanPhoneNumber;
    }
    
    @InvocableMethod(
        label='Remove Country Code from Phone' 
        description='Removes specified country code from full phone number'
        category='Phone Number'
    )
    public static List<Response> removeCountryCode(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for(Request req : requests) {
            Response resp = new Response();
            resp.cleanPhoneNumber = removeCountryCodeFromPhone(req.countryCode, req.fullPhoneNumber);
            responses.add(resp);
        }
        
        return responses;
    }
    
    private static String removeCountryCodeFromPhone(String countryCode, String fullPhoneNumber) {
        if(String.isBlank(countryCode) || String.isBlank(fullPhoneNumber)) {
            return fullPhoneNumber;
        }
        
        // Normalize inputs: remove spaces, dashes, parentheses
        String normalizedPhone = fullPhoneNumber.replaceAll('[^0-9+]', '');
        String normalizedCode = countryCode.replaceAll('[^0-9+]', '');
        
        // Handle both +prefix and without +
        String codeWithPlus = '+' + normalizedCode;
        String codeWithoutPlus = normalizedCode;
        
        Integer codeWithPlusLen = codeWithPlus.length();
        Integer codeWithoutPlusLen = codeWithoutPlus.length();
        
        // Check if phone starts with country code (with +)
        if(normalizedPhone.startsWith(codeWithPlus)) {
            return normalizedPhone.substring(codeWithPlusLen);
        }
        // Check if phone starts with country code (without +)
        else if(normalizedPhone.startsWith(codeWithoutPlus)) {
            return normalizedPhone.substring(codeWithoutPlusLen);
        }
        // Return original if no match
        else {
            return normalizedPhone;
        }
    }
}