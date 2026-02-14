/**********************************************************************************************************************
* Name               : SalesManagerReAssignmentBatch                                                        
* Description        : This batch will pickup all the lead records where no action is taken by the agent (Must be scheduled 5-15 mins)
* Usage              :                                                       
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
//Script to schedule batch 
//System.schedule('SalesManagerReAssignmentBatch-Every_00_Min', '0 0 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_05_Min', '0 5 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_10_Min', '0 10 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_15_Min', '0 15 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_20_Min', '0 20 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_25_Min', '0 25 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_30_Min', '0 30 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_35_Min', '0 35 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_40_Min', '0 40 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_45_Min', '0 45 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_50_Min', '0 50 * * * ?', new SalesManagerReAssignmentBatch() );
//System.schedule('SalesManagerReAssignmentBatch-Every_55_Min', '0 55 * * * ?', new SalesManagerReAssignmentBatch() );
global class SalesManagerReAssignmentBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful {
    private set<String> contactsIds;
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,10);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime currentDT = system.now(); //.addHours(-2);
        String query = 'Select id,Owner_Name__c,LeadSource from Lead where  status != \''+Constants.RETIRED+'\' and Status!= \''+Constants.DUPLICATE_LEAD+'\' AND KioskSection__c !=  \''+Constants.KIOSKSELECTION_WALKIN+'\'and isConverted=false AND LeadSource!= \'Broker Portal\' and Owner_Name__c = \'Sales Manager RR Queue\'';
        //String query='select id,ViewedbyAgents__c,ExecuteReassignment__c,AssignmentSLATime__c,OwnerId,LeadNumber__c from lead where ExecuteReassignment__c = false AND ViewedbyAgents__c = false AND isConverted=false and AssignmentSLATime__c !=null and AssignmentSLATime__c < :currentDT and status != \''+Constants.RETIRED+'\' and Status!= \''+Constants.DUPLICATE_LEAD+'\' and createdBy.Profile.Name != \''+Constants.SALES_MANAGER+'\' and KioskSection__c !=  \''+Constants.KIOSKSELECTION_WALKIN+'\' order by lastModifiedDate';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Lead> scope){
        map<id,Lead> leadIdsForReassignment = new map<id,Lead>(scope);
        if(!leadIdsForReassignment.isEmpty()){
            string subjectLike = '%'+Constants.TASK_DAY1+'%';
            list<Task> tasksToClose = [select id from Task where WhoId in :leadIdsForReassignment.keySet() and Status!= :Constants.TASK_COMPLETED and subject like :subjectLike];
            for(Task temptask : tasksToClose){
                temptask.Status=Constants.TASK_COMPLETED;
                temptask.TaskNumber__c = 0;
            }
            system.debug(tasksToClose.size());
            map<id,Lead> getAgentAssignment =RoundRobinAssignmentUtility.getAgentAssignment(leadIdsForReassignment);
            if(!getAgentAssignment.isEmpty()){
                try{
                    // SSP-452 - Added by Anil Kumar: Previously, we were using 'update', which caused all records to fail if any one failed.
                    // Now, using 'Database.update' with partial success handling to avoid full batch failure.
                    if (!tasksToClose.isEmpty()) {
                        Database.update(tasksToClose, false);
                    }
                    if (!getAgentAssignment.isEmpty()) {
                        Database.update(getAgentAssignment.values(), false);
                    }
                }catch(exception e){
                    system.debug('Error'+ e);
                    LoggerService.Save( LoggerService.addApexLog(e,'Sales Manager ReAssignment Batch','SalesManagerReAssignmentBatch','execute') );
                }
                
            }
        }
    }    
    global void finish(Database.BatchableContext bc){
        scheduleJob();
    }

	global static void scheduleJob() {
        Integer SalesManagerReAssignmentBatchScheduleTime = Integer.valueOf(System.Label.SalesManagerReAssignmentBatchSchedule);
        SalesManagerReAssignmentBatch objSchedule = new SalesManagerReAssignmentBatch();
		Datetime dt = system.now().addMinutes(SalesManagerReAssignmentBatchScheduleTime);
		string sCornExp = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        
        for(CronTrigger obj : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'SalesManagerReAssignmentBatch-Every_05_Min')]) {
            system.abortJob(obj.Id);
        }
			
		system.schedule('SalesManagerReAssignmentBatch-Every_05_Min', sCornExp, objSchedule);
    }    
}