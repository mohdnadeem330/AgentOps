/*
* Name               : CustomerUpdatePaymentWebService
* Description        : This class is used to update Payment details
*/
@RestResource (urlMapping = '/customer/updatepayment')
global without sharing class CustomerUpdatePaymentWebService {

    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            handler.response.data = updatePayment(jsonBody);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    global static PaymentModel updatePayment(String jsonBody) {
        PaymentModel paymentModel = new PaymentModel();

        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonBody);

        String resp = JSON.Serialize(requestMap.get('responseBody'));
        
        JSONParser parser = JSON.createParser(resp);

        String paymentId, authenticationId, reasonCode, decision, authenticationReferenceNumber, receiptNumber, referenceNumber, receiptId, authCode, onlinePaymentMessage;
        Decimal authorizedAmount = 0;
        while (parser.nextToken() != null) {
            if (parser.getText().equals('req_transaction_uuid')){
                parser.nextToken();
                paymentId = parser.getText().split('-')[0];
            } else if (parser.getText().equals('payer_authentication_transaction_id')) {
                parser.nextToken();
                authenticationId = parser.getText();
            } else if (parser.getText().equals('req_reference_number')) {
                parser.nextToken();
                receiptId = parser.getText().split('-')[0];
            } else if(parser.getText().equals('reason_code')) {
                parser.nextToken();    
                reasonCode = parser.getText();
            } else if(parser.getText().equals('decision')) {
                parser.nextToken();
                decision = parser.getText();
            } else if(parser.getText().equals('auth_trans_ref_no')) {
                parser.nextToken();
                authenticationReferenceNumber = parser.getText();    
            } else if(parser.getText().equals('transaction_id')) {
                parser.nextToken();
                receiptNumber = parser.getText();
            } else if(parser.getText().equals('bill_trans_ref_no')) {
                parser.nextToken();
                referenceNumber = parser.getText();
            } else if(parser.getText().equals('auth_code')) {
                parser.nextToken();
                authCode = parser.getText();
            } else if(parser.getText().equals('authorizedAmount')) {
                parser.nextToken();    
                authorizedAmount = Decimal.valueOf(parser.getText());
            } else if(parser.getText().equals('message')){
                parser.nextToken();
                if(parser.getText() != 'null' || parser.getText() != 'NULL'){
                    onlinePaymentMessage = parser.getText();
                }
            }
        }

        ReceiptAcknowledgement__c paymentRecord = new ReceiptAcknowledgement__c();
        paymentRecord.Id = receiptId;
        paymentRecord.AuthenticationId__c = authenticationId;
        paymentRecord.AuthenticationReferenceNumber__c = authenticationReferenceNumber;
        paymentRecord.Decision__c = decision;
        paymentRecord.JSONResponse__c = resp;
        paymentRecord.PaymentResponseMessage__c = onlinePaymentMessage;
        paymentRecord.ReasonCode__c = reasonCode;
        paymentRecord.Status__c = Constants.LINK_SENT;

        if (reasonCode == '100') {
            paymentRecord.Status__c = Constants.RECEIVED_PAYMENT_STATUS;
            paymentRecord.ReceiptDate__c = Date.Today();
            paymentRecord.ReferenceNumber__c = 'CC-' + authCode;
            paymentRecord.ChequeReceived__c = true;
            paymentRecord.OnlinePaymentCleared__c = true;
        }
        update paymentRecord;

        ReceiptAcknowledgement__c newReceipt = CustomerServiceUtility.getReceiptAcknowledgementDetail(' (Id = \'' + receiptId + '\') ')[0];
        paymentModel.receiptId = newReceipt.Id;
        paymentModel.receiptDetails = newReceipt;

        return paymentModel;
    }

    global class PaymentModel{
        public Id receiptId                                     {get;set;}
        public ReceiptAcknowledgement__c receiptDetails         {get;set;}
    }
}