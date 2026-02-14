global class BatchToAllSRCallout implements Schedulable, Database.Batchable<sObject>,Database.AllowsCallouts {
   
   String query='';
   global BatchToAllSRCallout (){
        this.query='select Id from HexaBPM__Service_Request__c where SyncStatus__c =\'Failed\'';
    }
    
    global BatchToAllSRCallout (String query){
        this.query=query;
    }
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToAllSRCallout(), 1);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(this.query);
    }
    
    global void execute(Database.BatchableContext BC, List<HexaBPM__Service_Request__c> recordTypeList){
        String whrClause = ' Id = \'' + recordTypeList.get(0).Id + '\'';
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithWhereClause(whrClause);
		System.debug('serviceRequestList>>>' + serviceRequestList);
        String recordTypeName = Utilities.getRecordTypeName('HexaBPM__Service_Request__c', serviceRequestList[0].RecordTypeId);
        
        if (!serviceRequestList.isEmpty()) {
            for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                serviceRequest.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            update serviceRequestList;
            RetriggerAPIController.callAPI(serviceRequestList, recordTypeName);        
        }
      
    }
    
    global void finish(Database.BatchableContext BC){

    }
}