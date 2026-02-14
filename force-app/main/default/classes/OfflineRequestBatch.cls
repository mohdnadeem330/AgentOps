global class OfflineRequestBatch implements Database.Batchable<sObject>, Database.Stateful,Schedulable {
	String status = 'Approved';
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime curretTime;
        If(Test.isrunningTest()){
             curretTime = System.now()+2;
        }else{
             curretTime = System.now();
        }
        String query = 'SELECT Name,Reason__c,StartTime__c,Status__c,EndTime__c,User__c FROM OfflineRequest__c WHERE Status__c=:status AND StartTime__c <=:curretTime AND EndTime__c >= :curretTime';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<OfflineRequest__c> lstOfflineRequest){
        set<Id> offlineUsers = new set<Id>();
        for(OfflineRequest__c objOfflineRequest : lstOfflineRequest){
            offlineUsers.add(objOfflineRequest.User__c);
        }
        if(!offlineUsers.isEmpty()){
            RoundRobinAssignmentUtility.setAgentOffline(offlineUsers);
        }
    }
	global void finish(Database.BatchableContext bc){
        try{
            set<Id> offlineUsers = new set<Id>();
            for(OfflineRequest__c objOfflineReq : [SELECT Name,Reason__c,StartTime__c,Status__c,EndTime__c,User__c FROM OfflineRequest__c WHERE Status__c=:status AND EndTime__c <: system.now() AND CreatedDate = TODAY]){
                offlineUsers.add(objOfflineReq.User__c);
            }
            if(!offlineUsers.isEmpty()){
                RoundRobinAssignmentUtility.setAgentAvailable(offlineUsers);
            }
        } catch(exception e) {
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(e, 'Offline Request Batch','OfflineRequestBatch', 'finish'));
        }
        
        OfflineRequestBatch.scheduleJob();
    }

    global static void scheduleJob() {
        Integer OfflineRequestBatchScheduleTime = Integer.valueOf(System.Label.Offline_Request_Batch_Schedule);
        OfflineRequestBatch objSchedule = new OfflineRequestBatch();
		Datetime dt = system.now().addMinutes(OfflineRequestBatchScheduleTime);
		string sCornExp = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        
        for(CronTrigger obj : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Offline Request Batch')]) {
            system.abortJob(obj.Id);
        }
			
		system.schedule('Offline Request Batch', sCornExp, objSchedule);
    }

	global void execute(SchedulableContext sc) {
        OfflineRequestBatch batch = new OfflineRequestBatch();
        database.executeBatch(batch, 200);
    }    
        
}