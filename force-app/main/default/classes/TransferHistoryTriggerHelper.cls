public class TransferHistoryTriggerHelper {
	// Method to remove DDA reference number when property is transferred.
    public static void updateSO(List<TransferHistory__c> transferHistoryList){
        system.debug('transferHistoryList:::'+transferHistoryList);  
        Set<Id> saleOrderIdSet = new Set<Id>();
        // yenshul@aldar for resale transfers
        Set<Id> salesOrderIdsForResale = new Set<Id>();
        List<SalesOrder__c> salesOrderToUpdate = new List<SalesOrder__c>();
        for(TransferHistory__c transferHistory: transferHistoryList){
            if(transferHistory.FromAccount__c != null && transferHistory.ToAccount__c != null){
               saleOrderIdSet.add(transferHistory.SalesOrder__c);
            }
            // yenshul@aldar for resale transfers
            salesOrderIdsForResale.add(transferHistory.SalesOrder__c);
        }
        List<SalesOrder__c> salesOrderList = [SELECT
                                              Id,
                                              Directdebitauthorityreferencenumber__c
                                              FROM SalesOrder__c
                                              WHERE Id IN:saleOrderIdSet
                                              AND Directdebitauthorityreferencenumber__c != null];
        system.debug('salesOrderList:::'+salesOrderList);        
        for(SalesOrder__c so: salesOrderList){
            salesOrderToUpdate.add(new SalesOrder__c (Id = so.Id, Directdebitauthorityreferencenumber__c = ''));
        }
        if(!salesOrderToUpdate.isEmpty()){
            update salesOrderToUpdate;
        }
        // yenshul@aldar for resale transfers
        if(!salesOrderIdsForResale.isEmpty()){
            ResaleService.processResaleTransfers(salesOrderIdsForResale);
        }
    }    
}