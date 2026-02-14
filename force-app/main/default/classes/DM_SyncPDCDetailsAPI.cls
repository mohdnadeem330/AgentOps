@RestResource(urlMapping = '/DM/PDCDetail')
Global class DM_SyncPDCDetailsAPI {
	 @HttpPost
    global static void doPost() { 
    	RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Validate required fields
            if (reqBodyMap == null || !reqBodyMap.containsKey('paymentid') || String.isBlank((String)reqBodyMap.get('paymentid'))) {
                throw new CustomException('Payment Id is required and cannot be empty');
            }/*else if (!reqBodyMap.containsKey('erpId') || String.isBlank((String)reqBodyMap.get('erpId'))) {
                throw new CustomException('ERP identity is required and cannot be empty');
            }*/else if (!reqBodyMap.containsKey('receiptErpId') || String.isBlank((String)reqBodyMap.get('receiptErpId'))) {
                throw new CustomException('Receipt can not be empty');
            }
			
            handler.response.data = new Map<String,String>{'message'=>processRequest(reqBodyMap)};
            handler.response.success = true;
            handler.finalize();
        } catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400; // Bad Request
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
            System.debug('CustomException: ' + ex.getMessage());
        }catch (Exception ex){
            // Handle any other exceptions that occur
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);
        }
    }
    
    global static String  processRequest(Map<String, Object> reqBodyMap){
        String paymentid = (String)reqBodyMap.get('paymentid');
        //String erpId = (String)reqBodyMap.get('erpId');
        List<Payment_Request__c> lstPaymentReq = [SELECT Id,Name,ERP_Receipt_Id__c,Received_Amount__c,Transaction_Date__c,Transaction_No__c,Payment_Type__c FROM Payment_Request__c WHERE Id=:paymentid/* AND ERP_Receipt_Id__c=:erpId*/];
        if(lstPaymentReq.isEmpty())
			 throw new CustomException('No Payment request found');            	
        Payment_Request__c paymntReq =   lstPaymentReq[0];
        /*paymntReq.ERP_Receipt_Id__c = String.valueOf(reqBodyMap.get('receiptErpId'));
        if((String)reqBodyMap.get('chequeOrpaymentDate') != null){
        	DateTime dt = DateTime.valueOf((String)reqBodyMap.get('chequeOrpaymentDate')); 
        	paymntReq.Transaction_Date__c = dt;    
        }*/
        
        paymntReq.Status__c = String.valueOf(reqBodyMap.get('status'));
        //paymntReq.Transaction_No__c =  String.valueOf(reqBodyMap.get('transNumber'));
        //paymntReq.Received_Amount__c = Decimal.valueOf(reqBodyMap.get('AreceivedAmt'));
        
        //try{
            UPDATE paymntReq;
        /*}Catch(Exception e){
            throw new CustomException('Error:'+e.getMessage());
        }*/
        return 'Payment Details Updated Successfully!';
    }
}