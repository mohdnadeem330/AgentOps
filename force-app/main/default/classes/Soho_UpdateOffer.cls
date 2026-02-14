@RestResource(urlMapping='/updateResaleOffer')
global class Soho_UpdateOffer {
  @HttpPost
    global static void updateOffer() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            String requestBody = handler.getRequestBody();
            if(!String.isEmpty(requestBody)){
                Resale_Offers__c resaleOffer = (Resale_Offers__c) JSON.deserialize(requestBody, Resale_Offers__c.class);
                Update resaleOffer;
                responseData.put('offerUpdated',TRUE);
                handler.response.success = true;
                handler.response.statusCode = 200;
                handler.response.message = 'Success';
                handler.response.data = responseData;
            }else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        }catch(DMLException dmlEx){
            Integer statusCode = 500;
            String errorMessage = dmlEx.getMessage();
            List<String> fieldErrorStrs = new List<String>();
            for(Integer i=0; i<dmlEx.getNumDml(); i++){
                if(dmlEx.getDmlStatusCode(i) == 'FIELD_CUSTOM_VALIDATION_EXCEPTION' || dmlEx.getDmlStatusCode(i) == 'FIELD_FILTER_VALIDATION_EXCEPTION'){
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
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = e.getMessage();
        }
        handler.finalize();
    }
}