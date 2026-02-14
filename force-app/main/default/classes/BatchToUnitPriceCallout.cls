global class BatchToUnitPriceCallout implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToUnitPriceCallout(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){

        Set<String> untFieldList = Schema.getGlobalDescribe().get('Unit__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(untFieldList);
        String fields = string.join(strList,',');

        String reprocessStatus = Constants.REPROCESS_PRICE;
        String query = 'SELECT ' + fields + ' FROM Unit__c WHERE PriceSyncStatus__c = \'Error\' AND ReprocessCallout__c != null AND ReprocessCallout__c =: reprocessStatus';

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Unit__c> unitList){
        List<UnitUpdateWrapper.PriceUpdateUnitRecord> unitsWithUpdate = new List<UnitUpdateWrapper.PriceUpdateUnitRecord>();
        List<Id> recordIds = new List<Id>();
        for (Unit__c unitRecord: unitList) {
            recordIds.add(unitRecord.Id);
            unitsWithUpdate.add(new UnitUpdateWrapper.PriceUpdateUnitRecord(unitRecord));
        }
        if (!unitsWithUpdate.isEmpty()) {
            String requestBody = JSON.serialize(new UnitUpdateWrapper.PriceUpdateUnits(unitsWithUpdate));
            System.debug('***Request Body***'+requestBody);
            CalloutToMuleSoft.calloutService(requestBody, true, Constants.PRICE_UPDATE, recordIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }
}