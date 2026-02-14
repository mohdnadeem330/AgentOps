public class InwardRemittanceTriggerHandler extends TriggerHandler {
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        InwardRemittanceTriggerHelper.linkVirtualAccountsAndOrders((List<Inward_Remittance__c>)newList);
    }

    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        Map<Id, Inward_Remittance__c> typedOldMap = new Map<Id, Inward_Remittance__c>((List<Inward_Remittance__c>)oldList);
        InwardRemittanceTriggerHelper.preventReceiptAcknowledgementUpdate((List<Inward_Remittance__c>)newList, typedOldMap);
    }
}