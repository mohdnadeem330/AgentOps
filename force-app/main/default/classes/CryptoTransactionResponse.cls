@RestResource (urlMapping = '/crypto/response')
global without sharing class CryptoTransactionResponse {
    
    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
            
        try{
                       
            PaymentResponse__c paymentResponse = new PaymentResponse__c();
            ReceiptAcknowledgement__c receiptAck;            
            
            String jsonBody = req.requestBody.toString();
            paymentResponse.JSONResponse__c = jsonBody.length() < 131072 ? jsonBody : '';
                        
            TransactionData transactionData = (TransactionData) JSON.deserialize(jsonBody, TransactionData.class);
            String transactionId = transactionData.TransactionID;
            
            paymentResponse.TransactionID__c = transactionId;
            paymentResponse.PaymentGateway__c = 'midChains';
            paymentResponse.Amount__c = Decimal.valueOf(transactionData.Amount);
            //if (transactionData.Status == 'COMPLETED') {
            //    receiptAck = [SELECT Id FROM ReceiptAcknowledgement__c WHERE CryptoTransactionId__c =: transactionId Limit 1];
            //}
            //if(receiptAck != null){
            //    //paymentResponse.ReceiptAcknowledgement__c = receiptAck.Id;
            //}
            //
            insert paymentResponse;
            
            handler.response.success = true;
            handler.response.message = 'Success';
            handler.response.statusCode = 200;
            handler.finalize();
        }catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    
    
    public class TransactionData {
        public String Id {get;set;} 
        public String Amount {get;set;} 
        public String Expiry {get;set;} 
        public String InvoiceID {get;set;} 
        public String created_at {get;set;} 
        public String CallbackURL {get;set;} 
        public String CustomerName {get;set;} 
        public String TransactionID {get;set;} 
        public String BankReference {get;set;} 
        public String TradeReference {get;set;} 
        public String UnitVAIBANNumber {get;set;} 
        public String SettlementCurrency {get;set;} 
    }
}