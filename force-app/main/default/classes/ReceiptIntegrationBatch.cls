/**********************************************************************************************************************
* Name               : ReceiptIntegrationBatch                                                        
* Description        : This batch will accept receipt Ids as parameter and will make calout for those receipts.
* Usage              : ReceiptRemittanceBatch                                                          
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil		     03 Sept 2022      	Initial Draft       
******************************************************************************************************************/
global class ReceiptIntegrationBatch implements  Database.Batchable<sObject>, Database.AllowsCallouts {
    public List<Id> raIds{get;set;}    
    
    global ReceiptIntegrationBatch(List<Id> receiptIds){
        raIds = new List<Id>();
        if(receiptIds!=null)
            this.raIds = receiptIds;
        else
            this.raIds = null;
    }
    //            database.executeBatch(new ReceiptIntegrationBatch(), batchSize);
    //                    Integer batchSize = Utilities.getConstantValue('ReceiptAPIBatchSize');
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, SyncStatus__c FROM ReceiptAcknowledgement__c WHERE Id IN: raIds';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ReceiptAcknowledgement__c> raList){
        Map<Id,ReceiptAcknowledgement__c> raMap = new Map<Id,ReceiptAcknowledgement__c>(raList);
        System.debug('raIds>>>' + raMap.keySet());
        if (!raMap.isEmpty()) {
            List<Id> raIdsToSent = new List<Id>();
            raIdsToSent.addAll(raMap.keySet());
            ReceiptCalloutHelper.PrepareDataForCallout(raIdsToSent);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}