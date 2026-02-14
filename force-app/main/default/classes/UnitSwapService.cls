/*
*********************************************************
Apex Class Name    : UnitSwapService
Created Date       : June 27 2025
@description       : This Class is used for Specfic for Unit Swap Service Requests
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class UnitSwapService {
    /*
    *********************************************************
    @Method Name    : blockTheSwappedUnit
    @author         : 
    @description    : Method used to block the swapped unit
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */ 
    public static void blockTheSwappedUnit(List<SObject> newSRList, Map<Id, SObject> oldSRMap) {
        List<Unit__c> unitList = new List<Unit__c>();
        List<Id> unitIds = new List<Id>();
        for (HexaBPM__Service_Request__c srRecord: (List<HexaBPM__Service_Request__c>)newSRList) {
            HexaBPM__Service_Request__c oldSR = !oldSRMap.isEmpty() ? (HexaBPM__Service_Request__c)oldSRMap.get(srRecord.Id) : null;
            if (srRecord.SwappedUnit__c != null && (oldSR == null || (oldSR.SwappedUnit__c != srRecord.SwappedUnit__c && oldSR.SwappedUnit__c == null))) {
                Unit__c unit = new Unit__c();
                unit.Id = srRecord.SwappedUnit__c;
                unit.Status__c = Constants.UNIT_STATUS_BLOCKED;
                unit.BlockedBy__c = UserInfo.getUserId();
                unit.BlockedDate__c = Datetime.now();
                unit.BlockedComments__c = Constants.UNIT_BLOCKED_COMMENT;
                unit.BlockedReason__c = Constants.UNIT_BLOCKED_REASON;
                unitList.add(unit);
                unitIds.add(srRecord.Unit__c);
                unitIds.add(srRecord.SwappedUnit__c);
            }            
        }
        if (!unitIds.isEmpty()) {
            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>([SELECT Id, Project__r.Name FROM Unit__c WHERE Id IN: unitIds]);
            for (HexaBPM__Service_Request__c srRecord: (List<HexaBPM__Service_Request__c>)newSRList) {
                if (unitMap.containsKey(srRecord.Unit__c) && unitMap.containsKey(srRecord.SwappedUnit__c) && unitMap.get(srRecord.Unit__c).Project__r.Name == unitMap.get(srRecord.SwappedUnit__c).Project__r.Name) {
                    srRecord.UnitFromSameProject__c = Constants.YES;
                } else if (srRecord.UnitFromSameProject__c != Constants.YES) {
                    srRecord.UnitFromSameProject__c = Constants.No;
                }
            }
        }
        if (!unitList.isEmpty()) {
            update unitList;
        }
    }    
 	/*
    *********************************************************
    @Method Name    : updateSwapUnits
    @author         : 
    @description    : Method to update the swapped unit details
    @param          : moveInRequests 
    @return         : void
    ********************************************************
    */
    public static void updateSwapUnits(List<HexaBPM__Service_Request__c> newSRList) {
        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        for(HexaBPM__Service_Request__c newRecord : newSRList) {
            Unit__c updateUnit = new Unit__c();
            updateUnit.Id = newRecord.SwappedUnit__c;
            updateUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
            updateUnit.AssignedToUser__c = UserInfo.getUserId();
            updateUnit.AllocationGroup__c = null;
            unitsToUpdate.add(updateUnit);
        }
        if(!unitsToUpdate.isEmpty()) {
            update unitsToUpdate;
        }
    }
}