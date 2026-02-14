@RestResource (urlMapping = '/cancel/directDebit')
global with sharing class CancelDirectDebitWebService {
    
    @HTTPPost
    global static void doPost( String directDebitRequestId, String cancellationReason){
        RestContextHandler handler = new RestContextHandler(true);   
        try {
            List<DirectDebitRequest__c> directDebitRequestListToUpdate = new List<DirectDebitRequest__c>();
            DirectDebitRequest__c directDebitRequest                   = new DirectDebitRequest__c();
            
            if(String.isNotBlank(directDebitRequestId) && directDebitRequestId != null && directDebitRequestId != ''){
                directDebitRequest.Id = directDebitRequestId;
                directDebitRequest.CancellationReason__c = cancellationReason;
                directDebitRequest.Status__c = 'Cancellation in progress';
                directDebitRequestListToUpdate.add(directDebitRequest);
            }
            
            if(!directDebitRequestListToUpdate.isEmpty()){
                upsert directDebitRequestListToUpdate;
                handler.response.success = true;
                handler.response.data    = directDebitRequestListToUpdate ;
                handler.finalize();
            }
        }
        catch (DMLException exc) {
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = exc.getDMLMessage(0);
            handler.finalize(exc);
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }  
    }
}