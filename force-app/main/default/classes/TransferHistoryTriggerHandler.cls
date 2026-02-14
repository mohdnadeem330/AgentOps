public class TransferHistoryTriggerHandler extends TriggerHandler {
    
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        TransferHistoryTriggerHelper.updateSO((List<TransferHistory__c>) newList);
    }
    
}