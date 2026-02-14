trigger PaymentGatewayEventTrigger on Payment_Gateway_Event__e (after insert) {
    PaymentGatewayEventTriggerHandler.onAfterInsert(Trigger.New);
}