@RestResource (urlMapping = '/updateInvoice')
global with sharing class BP_SubmitWeeklyCommissionReport extends BP_BaseRestResource{
    @HttpPost
    global static void excute(){ 
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            if(!String.isEmpty(requestBody)){   
                BP_SubmitWeeklyCommissionReport service = new BP_SubmitWeeklyCommissionReport();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else{
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
            String recordId = (String) requestBodyData.get('recordId');
            String statusValue = (String) requestBodyData.get('statusValue');
            String comment  = (String) requestBodyData.get('comment');
            
            return new ApiResponse(true, 200, 'Successfully submitted the response', updateStatus(recordId, statusValue ,comment ));
            
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Failed to Submitted Weekly Commission Report: ' + e.getMessage(), null);
        } 
    }
    
    public static InvoiceBundle__c updateStatus(String recordId, String statusValue ,string comment ){
        system.debug('recordId::'+recordId);
        
        String invoiceId = recordId;
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(id=invoiceId,status__c=statusValue, AgencyAdmin__c=userInfo.getUserId() ,OwnerID= userInfo.getUserId(), Comments__c = comment, SubmittedByAgencyDate__c = System.today());
        if(!Schema.sObjectType.InvoiceBundle__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update invoiceBundle;
        if( statusValue == Constants.STATUS_REJECTED || statusValue == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            Map<id,InvoiceBundle__c> documentmap = new Map<id,InvoiceBundle__c>();
            documentmap.put(invoiceBundle.Id,invoiceBundle);
            InvoiceBundleController.generateInvoiceDocumentFromVF(documentmap);
        }
        return invoiceBundle;
    }
}