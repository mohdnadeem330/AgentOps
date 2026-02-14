@RestResource (urlMapping = '/sendto/eSign')
global with sharing class SendToeSignWebService {

    @testVisible
    private static Boolean throwException = false;
    
    @HTTPPost
    global static void doPost(Id documentId){
        
        RestContextHandler handler = new RestContextHandler(true);

        try {   
            if(SendToeSignWebService.throwException){
                throw new CustomException();
            }
            if(documentId!=null){
               String messageRecieved = DownloadSODocsController.sendForESign(documentId);
               handler.response.message = messageRecieved;
               handler.response.success = true;
            }else{
                handler.response.message = 'Please provide document Id.';
                handler.response.success = false;
            } 
            handler.finalize(); 
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
}