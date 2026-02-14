trigger PaymentGatewayEventManagerTrigger on PaymentGatewayEventManager__e (after insert) {
    PaymentGatewayEventManagerTriggerHandler.onAfterInsert(Trigger.New);
}