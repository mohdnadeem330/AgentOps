@RestResource (urlMapping = '/log/contactdetail')
global with sharing class LogContactDetailWebService {
    
    @HttpPost
    global static void doPost(String recordId,String recordName) {

        RestContextHandler handler = new RestContextHandler(false);

        String message = Constants.SUCCESS_MESSAGE;
        Integer statusCode = Constants.STATUS_CODE_SUCCESS;
        Boolean isSuccessful = true;

        try {
         
            if(recordId !=null && String.isNotBlank(recordId) && recordId.length()==18){
                Utilities.createLogAudit(recordId,recordName);
            }
            else{
                isSuccessful = false;
                statusCode = Constants.STATUS_CODE_NOT_FOUND ;
                message = Constants.INCORRECT_RECORD_ID ;
            }

            handler.response.statusCode = statusCode;
            handler.response.message = message;
            handler.response.success = isSuccessful;
            handler.response.data = null;

            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }

    }

}