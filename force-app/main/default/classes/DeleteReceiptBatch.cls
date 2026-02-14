/**********************************************************************************************************************
* Name               : DeleteRemittanceBatch                                                        
* Description        : Batch class to delete receipts
* Usage              :                                                           
* Created By         : Muzammil Bajaria                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil Bajaria     15 Sept 2022       Initial Draft       

******************************************************************************************************************/
global class DeleteReceiptBatch implements Database.Batchable<sObject>,Schedulable {
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new DeleteReceiptBatch(), 100);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> arStatusList = new List<String>{'Cleared','Reversed','Remitted','Confirmed'};
        String query = 'SELECT Id,Name,Status__c,Markfordeletion__c  FROM ReceiptAcknowledgement__c ' ;
        query += ' WHERE Markfordeletion__c =true AND Status__c NOT IN : arStatusList  AND (  SyncStatus__c = \'Synced\'  OR ERPID__c = null )';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ReceiptAcknowledgement__c> receiptList) {
        system.debug('receiptList '+receiptList);
        Delete receiptList;
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
}