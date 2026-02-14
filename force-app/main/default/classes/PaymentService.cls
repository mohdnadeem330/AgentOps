public without sharing class PaymentService {
    
    /*public static ReceiptAcknowledgement__c getPaymentRecordById(String paymentId){

        ReceiptAcknowledgement__c paymentRec = [Select Id, AuthenticationId__c, AuthenticationReferenceNumber__c, Decision__c, JSONResponse__c, ReasonCode__c
                                    From ReceiptAcknowledgement__c WHERE Id =: paymentId];
        
        return paymentRec;
    }*/

    public static String validateSFPaymentLink(String paymentRecordId){

        list<ReceiptAcknowledgement__c> paymentRecords=[select id, createdDate, ReasonCode__c, SalesOrder__c, SalesOrder__r.Status__c, ServiceRequest__c from ReceiptAcknowledgement__c where id = :paymentRecordId AND 
        PaymentLinkExpiry__c >: system.now() WITH SECURITY_ENFORCED limit 1];

        List<String> status = new List<String>{Constants.STATUS_RESERVATION_IN_PROGRESS, Constants.OPPO_UNIT_STATUS_PENDING, Constants.STATUS_APPROVAL_PENDING, Constants.SO_STATUS_SOLD};
        //paymentRecords[0].SalesOrder__r.Status__c != Constants.STATUS_RESERVATION_IN_PROGRESS
        if(!paymentRecords.isEmpty()){
            if(paymentRecords[0].ReasonCode__c == '100'){
                return 'Payment already processed';
            } else if(paymentRecords[0].SalesOrder__c != null && !status.contains(paymentRecords[0].SalesOrder__r.Status__c)){
                if(paymentRecords[0].ServiceRequest__c != null){
                    return 'Please reach out to Aldar Customer Management : 800 ALDAR  or E-Mail: customermanagement@aldar.com';
                }
                return 'This Order is Invalid, Please contact SM';
            } else {
                return '';
            }
        }
        return 'Link Expired';
    }

    @AuraEnabled(cacheable=false)
    public static void insertReceiptAcknowledgementRecords(List<ReceiptAcknowledgement__c> receiptAcknowledgementList){
      insert receiptAcknowledgementList;
    }
    
    public static Map<Id,ReceiptAcknowledgement__c> createPaymentRecords(List<OpportunityEOI__c> newList){

        List<ReceiptAcknowledgement__c> paymentRecords = new List<ReceiptAcknowledgement__c>();
        Map<Id,ReceiptAcknowledgement__c> paymentRecordsMap = new Map<Id,ReceiptAcknowledgement__c> ();

        Timer__mdt paymentGatewayLinkTimer = Utilities.getTimer(Constants.PAYMENT_GATEWAY_LINK);

        String timerUnit = PaymentGatewayLinkTimer.Time__c;
        Integer timerDetails = Integer.valueOf(PaymentGatewayLinkTimer.Timer__c);

        if (timerUnit == Constants.HOURS) {
            timerDetails = timerDetails * 60;
        }

        for(OpportunityEOI__c OpportunityEOI : newList){

        ReceiptAcknowledgement__c paymentRecord = new ReceiptAcknowledgement__c(Amount__c = OpportunityEOI.InterestFee__c, Opportunity__c = OpportunityEOI.Opportunity__c, 
                                    CurrencyIsoCode = OpportunityEOI.Opportunity__r.CurrencyIsoCode,
                                    OpportunityEOI__c =  OpportunityEOI.Id, PaymentType__c =  OpportunityEOI.PaymentMode__c);

        paymentRecord.PaymentLinkExpiry__c = system.now().addMinutes(timerDetails);
        
        paymentRecords.add(paymentRecord);
        paymentRecordsMap.put(OpportunityEOI.Id,paymentRecord);
        }

        insert paymentRecords;
        return paymentRecordsMap;
    }
}