@RestResource (urlMapping = '/validateOtp')
global with sharing class BP_ValidateOTP extends BP_BaseRestResource{

@HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);   
            if(!String.isEmpty(requestBody)){   
                BP_ValidateOTP service = new BP_ValidateOTP();
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
            String contactId = (String) requestBodyData.get('contactId');
            return new ApiResponse(true, 200, 'OTP Validated Successfully', UtilitiesWithoutSharing.validateOTP(contactId));
        } catch (Exception e) {
            return new ApiResponse(false, 400,'Failed to validate OTP: ' + e.getMessage(), null);
        } 
    }
}