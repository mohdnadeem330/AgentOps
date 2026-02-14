@RestResource(urlMapping='/removeAgent')
global class BP_RemoveAgent extends BP_BaseRestResource{
    static List<String> FieldExceptionCodes = new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION', 'FIELD_FILTER_VALIDATION_EXCEPTION', 'INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'};
    static String contactId; static String status;
    @HttpPost
    global static void deativateBrokerContactUser() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            
            String requestBody = handler.getRequestBody();
            if(!String.isEmpty(requestBody)){
                Map<String,Object> requestData = (Map<String,Object>) JSON.deserializeUntyped(requestBody);
        
                contactId = (String) requestData.get('contactId');
                status = (String) requestData.get('status');
                
                if(String.isNotBlank(contactId)){
                    if(String.isNotBlank(status)){

                        Map<String, String> params = RestContext.request.params;
                        BP_RemoveAgent service = new BP_RemoveAgent();
                        ApiResponse response = service.processRequest(params, null);

                        handler.response.data = response.data;
                        handler.response.success = true;
                        handler.response.statusCode = response.statusCode;
                        handler.response.message = response.message;
                        // Contact obj = new Contact();
                        // obj.Id = contactId;
                        // obj.AgentStatus__c = status;
                        // update obj;

                        // responseData.put('contactId', obj.Id); 
                    
                        // handler.response.success = true;
                        // handler.response.statusCode = 200;
                        // handler.response.message = 'Success';
                        // handler.response.data = responseData;
                    }else{
                        handler.response.success = false;
                        handler.response.statusCode = 200;
                        handler.response.message = 'Status can not be Blank';
                        handler.response.data = responseData;
                    }
                }else{
                    handler.response.success = false;
                    handler.response.statusCode = 200;
                    handler.response.message = 'ContactId can not be Blank';
                    handler.response.data = responseData;
                }
                
            }else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }

        }
        /*catch(DMLException dmlEx){
            Integer statusCode = 500;
            String errorMessage = dmlEx.getMessage();
            List<String> fieldErrorStrs = new List<String>();
            for(Integer i=0; i<dmlEx.getNumDml(); i++){
                if(FieldExceptionCodes.contains(dmlEx.getDmlStatusCode(i))){
                    fieldErrorStrs.add(dmlEx.getDmlMessage(i));
                }
            }
            if(!fieldErrorStrs.isEmpty()){
                statusCode = 300;
                errorMessage = String.join(fieldErrorStrs, ' ');
            }
            handler.response.success = false;
            handler.response.statusCode = statusCode;
            handler.response.message = errorMessage;
        }
*/
        catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = e.getMessage();
        }
        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
           String message = (status == 'In Active') ? 'Agent is deactivated Successfully' : 'Agent is activated Successfully';

            return new ApiResponse(true, 200,message, updateContact(contactId, status));
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Agent is deactivation failed ' + e.getMessage(), null);
        } 
    }

    private static Contact updateContact(String contactId, String status){
        Contact obj = new Contact();
        obj.Id = contactId;
        obj.AgentStatus__c = status;
        update obj;

        return obj;
        
    }
}