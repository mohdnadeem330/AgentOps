global class UnitUpdateBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,WebFloorPlan__c,AffectionPlan__c from unit__c where WebFloorPlan__c !=null or  AffectionPlan__c !=null';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Unit__c> scope){
        UnitTriggerHandler.createUpdateDocumentPlaceHolder(new map<id,Unit__c>(scope));
    }    
    global void finish(Database.BatchableContext bc){}    
}