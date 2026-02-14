@RestResource (urlMapping = '/otpvalidation')
global with sharing class BP_OTPValidations extends BP_BaseRestResource{

    static String message = '';
    static Boolean isSuccess = true;

    static String OTP_MESSAGE = 'Failed: Invalid OTP';
    static String OTP_SUCCESS_MESSAGE = 'Succes';

    @HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);   
            if(!String.isEmpty(requestBody)){   
                BP_OTPValidations service = new BP_OTPValidations();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            
            Id sObjectId = (Id) requestBodyData.get('sObjectId');
            String functionality = (String) requestBodyData.get('functionality');
            String type = (String) requestBodyData.get('type');
            String otp = (String) requestBodyData.get('otp');


            return new ApiResponse(isSuccess, 200, message, validateOTP(sObjectId, functionality, type, otp));
        } catch (Exception e) {
            return new ApiResponse(false, 400,'Failed to validate OTP: ' + e.getMessage(), null);
        } 
    }

    public static String validateOTP(Id sObjectId, String funcationlity, String type, String otp){
        
        if(funcationlity == 'Agency Registration'){

            // sobjectId means SR Record Id
            HexaBPM__Service_Request__c getSR = BrokerAgencyRegistrationController.getOtpDetails(String.valueOf(sObjectId));

            if(getSR != null && getSR.OTPNumber__c == otp){

                // Update SR to Submitted after verified OTP
                BrokerAgencyRegistrationController.updateServiceRequestRecordStatus(getSR.Id, Constants.SUBMITTED);
                message = OTP_SUCCESS_MESSAGE;
                return message;
            }
            isSuccess = false;
            message = OTP_MESSAGE;
            return message;
        }
        else if(funcationlity == 'Update Bank Details'){
            // sobjectId means Account Record Id
            List<Contact> listAgents = UserProfileController.getOtpDetails(String.valueOf(sObjectId));
            //Map<Id, Contact> listAgents = new Map<Id,Contact>(listAgents );
            
            if(listAgents != null && !listAgents.isEmpty() && listAgents[0].BrokerLoginOTPNumber__c == otp){
                message = OTP_SUCCESS_MESSAGE;
                return message;
            }
            isSuccess = false;
            message = OTP_MESSAGE;
            return message;
        }
        else if(funcationlity == 'Add Agent'){
            // sobjectId means Contact/ Primay Admin Record Id
            List<Contact> listAgents = UtilitiesWithoutSharing.validateOTP(String.valueOf(sObjectId));
            
            if(listAgents != null && !listAgents.isEmpty() && listAgents[0].BrokerLoginOTPNumber__c == otp){
                message = OTP_SUCCESS_MESSAGE;
                return message;
            }
            isSuccess = false;
            message = OTP_MESSAGE;
            return message;
        }
        return message;
    } 
}