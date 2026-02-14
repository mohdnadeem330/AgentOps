@RestResource (urlMapping = '/document/mandatoryCheck')
global with sharing class DocumentVerificationWebService {
    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);

        try {   
            
            final Integer STATUS_CODE_ACCOUNT_NOT_EXIST = 701;
            final Integer STATUS_CODE_INPUT_NOT_CORRECT = 702;
            String ERROR_NO_ID_FOUND ='Please provide account id or opportunity id to proceed';
            String ERROR_NO_ACCOUNT_ID_FOUND ='Account Id does not exist in org';
            
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            DocumentRequest documentVerification = (DocumentRequest)JSON.deserializeStrict(jsonBody,DocumentRequest.class);
            system.debug('documentVerification '+documentVerification);
            
            if(String.isBlank(documentVerification.opportunityId)){
                Exceptions.DocumentVerificationException exc = new Exceptions.DocumentVerificationException();
                exc.statusCode = STATUS_CODE_INPUT_NOT_CORRECT;
                exc.setMessage(ERROR_NO_ID_FOUND);
                throw exc;
            }
            
            SalesOrderService.MandatoryDocWrapper wrapperToReturn = SalesOrderService.getMandatoryDocs(documentVerification.opportunityId);
            system.debug('wrapperToReturn '+wrapperToReturn);
            handler.response.data = wrapperToReturn ; 
            handler.response.success = true;
            handler.finalize();
            
        } catch(Exceptions.DocumentVerificationException ex){
            handler.response.success = false;
            handler.response.statusCode = 801;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    global class DocumentRequest{
        public Id accountId      {get;set;}
        public Id opportunityId  {get;set;}
    }
}