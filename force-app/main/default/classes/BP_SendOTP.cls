@RestResource(urlMapping = '/sendOtp')
global with sharing class BP_SendOTP extends BP_BaseRestResource {

    @HttpPost
    global static void excute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test ' + RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            System.debug('requestBody::::' + requestBody);   

            if (!String.isEmpty(requestBody)) {   
                BP_SendOTP service = new BP_SendOTP();
                BP_BaseRestResource.ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }

    global override BP_BaseRestResource.ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            String contactId = (String) requestBodyData.get('contactId');
            String type = (String) requestBodyData.get('type');
            String value = (String) requestBodyData.get('value');

            return new BP_BaseRestResource.ApiResponse(true, 200, 'OTP Sent Successfully', BP_UtilitiesWithoutSharing.sendOTP(contactId, type, value));
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_SendOTP', 'processRequest - contactId: ' + ((Map<String, Object>)JSON.deserializeUntyped(requestBody)).get('contactId')));
            return new BP_BaseRestResource.ApiResponse(false, 400, 'Failed to send OTP: ' + e.getMessage(), null);
        } 
    }
}