public with sharing class EOIRangeTriggerHandler extends TriggerHandler{

    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        EOIRangeService.newEOIRangeRecord(newList);
    }
}