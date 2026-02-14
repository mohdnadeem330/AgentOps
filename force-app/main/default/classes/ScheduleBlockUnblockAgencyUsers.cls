//Schedule from UI to run daily at 1 AM
global without sharing class ScheduleBlockUnblockAgencyUsers implements Schedulable ,Database.Batchable<sObject> {
    global void execute(SchedulableContext sc) {
        database.executeBatch(new ScheduleBlockUnblockAgencyUsers());
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        list<string> lstStatus = new list<string>{
        	Constants.STATUS_APPROVAL_PENDING
        };
        string strQuery = 'select Id,AgencyStatus__c,RegistrationExpiryDate__c from Account where RegistrationExpiryDate__c!=null and AgencyStatus__c!=null and  RegistrationExpiryDate__c < TODAY AND AgencyStatus__c NOT IN (\'Blocked\',\'Pending Verification\')';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, list<Account> lstAccounts){
    	system.debug('execute ScheduleBlockUnblockAgencyUsers');
        try{
            AccountService.blockAgencyUsers(lstAccounts);
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'Block/Unblock Agency Users','ScheduleBlockUnblockAgencyUsers','ScheduleBlockUnblockAgencyUsers'));
        }
    }
    
    global void finish(Database.BatchableContext BC){
    	/*ScheduleBlockUnblockAgencyUsers objSchedule = new ScheduleBlockUnblockAgencyUsers();
		Datetime dt = system.now().addMinutes(1440);
		string sCornExp = '0 '+dt.minute()+' '+dt.hour()+' '+dt.day()+' '+dt.month()+' ? '+dt.year();
		for(CronTrigger obj : [select Id from CronTrigger where CronJobDetailId IN (SELECT Id FROM CronJobDetail where Name = 'BlockUnblockAgencyUsers Batch Process')])
			system.abortJob(obj.Id);
		system.schedule('BlockUnblockAgencyUsers Batch Process', sCornExp, objSchedule);*/
    }
}