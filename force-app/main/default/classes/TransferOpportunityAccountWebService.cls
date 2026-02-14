@RestResource(urlMapping='/query/useExistingAccount/*')
global with sharing class TransferOpportunityAccountWebService {
    @HttpPost
    global static void transferOpportunity() {
        RestRequest req = RestContext.request;
        RestContextHandler handler = new RestContextHandler(false);
        
        try{
            String newId =  handler.getRequestBodyMap().get('newId');
            String existingId =  handler.getRequestBodyMap().get('existingId');
            Boolean status = UseExistingAccount.updateOpportunity(newId,existingId);
            handler.response.success = true;
            handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
            handler.response.data = status;
            handler.finalize();
        } catch(Exception e){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'An error occurred: ' + e.getMessage();
            handler.finalize(e);
        }
    }
}