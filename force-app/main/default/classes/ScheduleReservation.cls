global without sharing class ScheduleReservation implements Schedulable ,Database.Batchable<sObject> {
    global void execute(SchedulableContext sc) {
        database.executeBatch(new ScheduleReservation());
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Datetime dtNow = system.now();
        List<string> lstStatus = new List<string>{Constants.APPROVE_STATUS};
        string strQuery = 'select Id,unit__c,Opportunity__c,Opportunity__r.ReservationApprovalRequestTime__c,Opportunity__r.ReservationApprovalStatus__c,Opportunity__r.ReservationApprovalExpiry__c from SalesOrder__c where Opportunity__r.ReservationApprovalStatus__c IN : lstStatus and Opportunity__r.ReservationApprovalExpiry__c <=: dtNow';
        system.debug(dtNow+'**Current Time**'+strQuery);
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> lstSalesOrder){
    	system.debug('execute ScheduleReservation');
        try{
            OpportunityUnitSearchController.expiredReservation(lstSalesOrder);
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'Changing the Reservation Approval Status','ScheduleReservation','ScheduleReservation'));
        }
    }
    
    global void finish(Database.BatchableContext BC){
        /*
    	ScheduleReservation objSchedule = new ScheduleReservation();
		Datetime dt = system.now().addMinutes(1);
		string sCornExp = '0 '+dt.minute()+' '+dt.hour()+' '+dt.day()+' '+dt.month()+' ? '+dt.year();
		for(CronTrigger obj : [select Id from CronTrigger where CronJobDetailId IN (SELECT Id FROM CronJobDetail where Name = 'Reservation Batch Process')])
			system.abortJob(obj.Id);
		system.schedule('Reservation Batch Process', sCornExp, objSchedule);
        */
    }
}