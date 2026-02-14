public class PaymentGatewayEventManagerTriggerHandler{
    public static void onAfterInsert(List<PaymentGatewayEventManager__e> pgEventList){
        Set<Id> receiptAckIdSet = new Set<Id>();
        for(PaymentGatewayEventManager__e pgEvent : pgEventList){
            if(string.isNotBlank(pgEvent.Receipt_Acknowledgement_Id__c) && string.isNotBlank(pgEvent.Receipt_Type__c) && pgEvent.Receipt_Type__c.equalsIgnoreCase('Charge Fee')){
                receiptAckIdSet.add((Id)pgEvent.Receipt_Acknowledgement_Id__c);
            }
        }
        if(!receiptAckIdSet.isEmpty()){
            ReceiptAcknowledgementTriggerHandler.autoCloseServiceChargeFeeStepOnSR([SELECT Id,Receipt_Type__c,Status__c,ServiceRequest__c FROM ReceiptAcknowledgement__c WHERE Id IN :receiptAckIdSet],null,'PlatformEventTrigger');
        	ReceiptAcknowledgementTriggerHandler.syncRelatedOtherServiceChargeDetails(receiptAckIdSet);
        }
    }
}