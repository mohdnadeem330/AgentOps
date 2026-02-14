trigger PaymentRequestTrigger on Payment_Request__c (after insert,After Update,After delete) { 
    new PaymentRequestTriggerHandler().run('Payment_Request__c');
}