public  class PaymentResponseHandler {

    public string resp {get; set;}
    private static String paymentId;
    public static String reasonCode {get; set;}
    private static String authenticationId;
    private static String decision;
    private static String authenticationReferenceNumber;

    public PaymentResponseHandler(){
        reasonCode='';
    }
  

    public void populateFieldsFromResponse(String response){

        JSONParser parser = JSON.createParser(resp);

        paymentId='';

        while(parser.nextToken() != null){

            if(parser.getText().equals('req_transaction_uuid')){
                parser.nextToken();
                paymentId = parser.getText().split('-')[0];
            
            }else if(parser.getText().equals('payer_authentication_transaction_id')){
                parser.nextToken();
                authenticationId = parser.getText();
        
            }else if(parser.getText().equals('reason_code')){
                parser.nextToken();    
                reasonCode = parser.getText();
    
            }else if(parser.getText().equals('decision')){
                parser.nextToken();
                decision = parser.getText();
        
            }else if(parser.getText().equals('auth_trans_ref_no')){
                parser.nextToken();
                authenticationReferenceNumber = parser.getText();        
            }           
        }
    }

    public void updatePaymentRecord(){

        resp = JSON.Serialize(ApexPages.currentPage().getParameters());

        populateFieldsFromResponse(resp);

        String status = Constants.DEFAULT_PAYMENT_STATUS;
        if(String.isNotBlank(paymentId)){
            
            if(reasonCode.equals(Constants.SUCCESS_REASON_CODE)){
                //sendSuccessEamil(paymentId);
                status = Constants.RECEIVED_PAYMENT_STATUS;
            }

            ReceiptAcknowledgement__c paymentRecord= new ReceiptAcknowledgement__c(id=Id.valueOf(paymentId), AuthenticationId__c=authenticationId, AuthenticationReferenceNumber__c=authenticationReferenceNumber, 
                                                    Decision__c=decision, JSONResponse__c=resp, ReasonCode__c=reasonCode, Status__c=status);

            update paymentRecord;
        }
    }

    public static void sendSuccessEamil(String paymentRecordId){

        ReceiptAcknowledgement__c paymentRecord = [SELECT Id, OpportunityEOI__r.Opportunity__r.Contact__r.Id, OpportunityEOI__r.Opportunity__r.Contact__r.Email,
         OpportunityEOI__r.Opportunity__r.Owner.Email FROM ReceiptAcknowledgement__c WHERE Id =: paymentRecordId];

        EmailTemplate emailTemplate = Utilities.getEmailTemplate(Constants.SUCCESS_PAYMENT);
        Messaging.SingleEmailMessage mail = Utilities.getEmailInstance(paymentRecord.OpportunityEOI__r.Opportunity__r.Contact__r.Id,emailTemplate.Id,paymentRecord.Id,new List<String>{paymentRecord.OpportunityEOI__r.Opportunity__r.Contact__r.Email, paymentRecord.OpportunityEOI__r.Opportunity__r.Owner.Email},null,null,null,null,null,null,Utilities.getOrgWideEmailAddressId());
        Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{mail});
    }
}