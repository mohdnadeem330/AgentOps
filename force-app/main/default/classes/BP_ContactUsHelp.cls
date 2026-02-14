@RestResource(urlMapping='/getContactUsHelp')
global with sharing class BP_ContactUsHelp extends BP_BaseRestResource{
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            String requestBody = RestContext.request.requestBody.toString();
            
            if (!String.isEmpty(requestBody)) {
                BP_ContactUsHelp service = new BP_ContactUsHelp();
                Map<String, String> params = RestContext.request.params;
                ApiResponse response = service.processRequest(params, requestBody);
                
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
            handler.response.message = 'Error: ' + ex.getMessage();
        }
        
        handler.finalize();
    }
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            contactWrapper wrap = new contactWrapper();
            wrap.SodicTeamMembers = ContactUsController.getSodicTeamMembers();
            wrap.BMAndSMTeamMembers = ContactUsController.getBMandSMTeam();
            return new ApiResponse(true, 200, 'Data fetched successfully', null);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to process request: ' + e.getMessage(), null);
        }
    }

    public class contactWrapper{
        public List<Contact> SodicTeamMembers;
        public List<User> BMAndSMTeamMembers;
    }
}