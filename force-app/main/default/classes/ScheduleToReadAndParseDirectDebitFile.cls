global class ScheduleToReadAndParseDirectDebitFile implements Schedulable{
	 
    global void execute(SchedulableContext sc) {
        Set<Id> ddResponseFileIds = new Set<Id>();
        List<DDResponseFiles__c> ddResponseFilesList = [SELECT 
                                                        Id,
                                                        Name,
                                                        Status__c,
                                                        Type__c,
                                                        Bank__c,
                                                        SkippedRecordValues__c
                                                        FROM DDResponseFiles__c
                                                        WHERE Status__c = 'Unprocessed'
                                                        ORDER BY isAckNack__c DESC];
        for(DDResponseFiles__c ddResponseFile: ddResponseFilesList){
            ddResponseFileIds.add(ddResponseFile.Id);
        }
        if(!ddResponseFileIds.isEmpty()){
            if(test.isRunningTest() ){
                BatchToReadAndParseDirectDebitFile batchToExecute = new BatchToReadAndParseDirectDebitFile(ddResponseFileIds);
                database.executeBatch(batchToExecute);
            }else{
                BatchToReadAndParseDirectDebitFile batchToExecute = new BatchToReadAndParseDirectDebitFile(ddResponseFileIds);
                database.executeBatch(batchToExecute, 1);
            }
            
        }
    }
}