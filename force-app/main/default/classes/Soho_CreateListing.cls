@RestResource(urlMapping='/createListing')
global class Soho_CreateListing {
    @HttpPost
    global static void createListing() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            
            String requestBody = handler.getRequestBody();
            if(!String.isEmpty(requestBody)){
                Case resaleCase = (Case) JSON.deserialize(requestBody, Case.class);
                resaleCase.RecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
                resaleCase.Status = ResaleConstants.CASE_NEW;
                // resaleCase.Origin = ResaleConstants.CASE_ORIGIN_ONLINE; // 'Online'
                resaleCase.Origin = ResaleConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
                resaleCase.ResaleListingExclusiveness__c = 'Exclusive';
                insert resaleCase;
                
                Case resaleCaseDB = [SELECT Id, CaseNumber FROM Case WHERE Id =: resaleCase.Id];
                responseData.put('CaseNo', resaleCaseDB.CaseNumber);
                
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