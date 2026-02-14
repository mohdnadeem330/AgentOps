/*
* Name               : CustomerCreatePaymentWebService
* Description        : This class is used to create stripe Payment details
*/
@RestResource (urlMapping = '/customer/createstripepayment')
global without sharing class CustomerCreatePaymentWebService {
    
    @HTTPPost
    global static void doPost(){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            handler.response.data = createStripePayment(jsonBody);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = e.getStackTraceString() +e.getMessage();
            handler.finalize(e);
        }
    }    
    public static CustomerCreateReceiptController.PaymentModel createStripePayment(String jsonBody) {
       return CustomerCreateReceiptController.createReceipt(jsonBody);
                } 
    
}