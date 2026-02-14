@RestResource (urlMapping = '/getAgentsDoc')
global with sharing class BP_GetAgentsDoc extends BP_BaseRestResource{

@HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);   
            if(!String.isEmpty(requestBody)){   
                BP_GetAgentsDoc service = new BP_GetAgentsDoc();
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
            String role = (String) requestBodyData.get('role');

            return new ApiResponse(true, 200, 'Documents are fetched successfully', BrokerAgentsController.getUploadedFiles(contactId, role));
        } catch (Exception e) {
            return new ApiResponse(false, 400,'Failed to fetch Agent\'s documents : ' + e.getMessage(), null);
        }
    }
}