global class SalesOrderIntegrationBatch  implements  Database.Batchable<sObject>, Database.AllowsCallouts {
    
    /**********************************************************************************************************************
* Name               : SalesOrderIntegrationBatch                                                        
* Description        : This batch will accept so Ids as parameter and will make calout for those salesorder.
* Usage              :                                                           
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil		     12 May 2023      	Initial Draft       
******************************************************************************************************************/
    public set<Id> soIds{get;set;}    
    
    global SalesOrderIntegrationBatch(set<Id> soIdsToExecute){
        soIds = new set<Id>();
        if(soIdsToExecute!=null)
            this.soIds = soIdsToExecute;
        else
            this.soIds = null;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('++soIds '+soIds);
        String query = 'SELECT Id, Name, SyncStatus__c FROM SalesOrder__c WHERE Id IN: soIds';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> soList){
        Map<Id,SalesOrder__c> soMap = new Map<Id,SalesOrder__c>(soList);
        System.debug('soIds>>>' + soMap.keySet());
        if (!soMap.isEmpty()) {
            List<Id> soIdsToSent = new List<Id>();
            soIdsToSent.addAll(soMap.keySet());
            SalesOrderCalloutHelper.PrepareDataForCallout(soIdsToSent, false, new Map<String, String>());
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
    
    
}