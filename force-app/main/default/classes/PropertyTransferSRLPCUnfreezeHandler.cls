/*
Name : PropertyTransferSRLPCUnFreezeHandler
Desc : Handles unfreezing of LPC dates when a Property Transfer Service Request is cancelled.
Date : 15/10/2025
*/

public class PropertyTransferSRLPCUnfreezeHandler {
    
    public static void handleServiceRequestStatusChange(List<HexaBPM__Service_Request__c> newList, Map<Id, HexaBPM__Service_Request__c> oldMap) {
        
        Id propertyTransferRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer');
        
        List<Id> srIdsToUnfreeze = new List<Id>();
        
        for (HexaBPM__Service_Request__c sr : newList) {
            HexaBPM__Service_Request__c oldSr = oldMap.get(sr.Id);
            
            // Unfreeze only when SR moves to Cancelled status
            if (sr.RecordTypeId == propertyTransferRecordTypeId &&
                sr.HexaBPM__External_Status_Code__c == Constants.SR_STATUS_CANCELLED &&  (oldSr == null || oldSr.HexaBPM__External_Status_Code__c != Constants.SR_STATUS_CANCELLED)) {
                    srIdsToUnfreeze.add(sr.Id);
                }
        }
        
        if (!srIdsToUnfreeze.isEmpty()) {
            unfreezeInstallmentLines(srIdsToUnfreeze);
        } else {
            System.debug('No Service Requests found to unfreeze.');
        }
    }
    
    /**
* @description Unfreeze InstallmentLines when ServiceRequest is cancelled
*/
    public static void unfreezeInstallmentLines(List<Id> serviceRequestIds) {
        try {
            // STEP 1: Get ServiceRequests that have SalesOrders
            List<HexaBPM__Service_Request__c> serviceRequests = [
                SELECT Id, SalesOrder__c
                FROM HexaBPM__Service_Request__c
                WHERE Id IN :serviceRequestIds
                AND SalesOrder__c != null
            ];
            
            if (serviceRequests.isEmpty()) {
                System.debug('No ServiceRequests with SalesOrders found');
                return;
            }
            
            // STEP 2: Get SalesOrder IDs from ServiceRequests
            Set<Id> salesOrderIds = new Set<Id>();
            for (HexaBPM__Service_Request__c sr : serviceRequests) {
                salesOrderIds.add(sr.SalesOrder__c);
            }
            
            // STEP 3: Get frozen InstallmentLines that need to be unfrozen
            List<InstallmentLines__c> installmentLinesToUnfreeze = [
                SELECT Id, LPCFreezeDate__c, LPCFreezeUntilDate__c, isFreezeByTransferSR__c
                FROM InstallmentLines__c
                WHERE SalesOrder__c IN :salesOrderIds
                AND isFreezeByTransferSR__c = true
            ];
            
            // STEP 4: Clear freeze information from InstallmentLines
            List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
            
            for (InstallmentLines__c il : installmentLinesToUnfreeze) {
                il.LPCFreezeDate__c = null;
                il.LPCFreezeUntilDate__c = null;
                il.isFreezeByTransferSR__c= false;
                il.SyncStatus__c = 'In Progress';
                installmentLinesToUpdate.add(il);
            }
            
            // STEP 5: Save changes to database
            if (!installmentLinesToUpdate.isEmpty()) {
                update installmentLinesToUpdate;
                System.debug('Successfully unfroze ' + installmentLinesToUpdate.size() + ' InstallmentLines');
            } else {
                System.debug('No InstallmentLines found to unfreeze');
            }
            
        } catch (Exception e) {
            System.debug('Error in unfreezeInstallmentLines: ' + e.getMessage());
        }
    }
}