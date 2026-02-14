/**********************************************************************************************************************
* Name               : DTStepAutoCloseBatch                                                        
* Description        : Class to Open the new step for 'Court filing by Legal' automatically if not one present earlier
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
* 1.1           Saravanan Sekar     28/08/2023      Updated Logic to process only SRs for which the Court filing step wasn't created yet       
******************************************************************************************************************/
//To be scheduled to run daily
global class DTStepAutoCloseBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
    public string StepName='Court filing by Legal';
    
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,50);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //SS_DandT_Revamp_SP15-Start
        //Get Court filing by legal step and closure date of SR today
        String query='SELECT Id, SalesOrder__c, (Select Id From HexaBPM__Steps_SR__r Where HexaBPM__Summary__c=\''+StepName+'\') FROM HexaBPM__Service_Request__c WHERE StepClosureDate__c = TODAY AND SRType__c =\'Default And Termination\'  AND HexaBPM__External_Status_Name__c != \'Closed\'';
        if(Test.isRunningTest()) {
            query='SELECT Id, SalesOrder__c, (Select Id From HexaBPM__Steps_SR__r Where HexaBPM__Summary__c=\''+StepName+'\') FROM HexaBPM__Service_Request__c Limit 1';
        }
        //SS_DandT_Revamp_SP15-End
        System.debug('>> query > '+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<HexaBPM__Service_Request__c> scope){
        Set<Id> srId = new Set<Id>();
        Map<Id, String> soIdStatus = new Map<Id, String>();//SS_KEEP SO Id to update the Hold Reason Code

        System.debug('>> scope > '+scope);
        
        for(HexaBPM__Service_Request__c sr:scope) {
            //SS_DandT_Revamp_SP15-Start
            //If there is a step already created, then donot create
            if(sr.HexaBPM__Steps_SR__r.IsEmpty()) {
                srId.add(sr.Id);
                System.debug('>> empty > '+sr.Id);
                soIdStatus.put(sr.SalesOrder__c,ALD_Constants.LEGAL_FLAG);//SS_KEEP SO Id to update the Hold Reason Code as Legal Submitted to External Counsel 260923
            }
            //SS_DandT_Revamp_SP15-End
        }
        if(!srId.IsEmpty()) {
            DefaultAndTerminationUtility.autoTransferToLeagal(srId);//recordToProcess.keySet());
            ALD_DandTSR_Handler_CC.updateSalesOrderHoldReason(soIdStatus);

        }
    }    
    global void finish(Database.BatchableContext bc){}    
}