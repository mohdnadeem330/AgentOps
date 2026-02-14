public with sharing class AllocationGroupUserTriggerHandler extends TriggerHandler{

    //*** AfteBefore Delete Action***//
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        //----Remove users from public group to restrict access the inventory
        AllocationGroupUserService.deletedAllocationGroupMembers(oldList);
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //---- Add users to public group to access the inventory
        AllocationGroupUserService.newAllocationGroupMembers(newList);
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        //---- Share/Unshare with users when End is modified to a future date or past date
        Map<Id, AllocationGroupUser__c> newAGUserMap = new Map<Id, AllocationGroupUser__c>();
        Map<Id, AllocationGroupUser__c> oldAGUserMap = new Map<Id, AllocationGroupUser__c>();

        for(AllocationGroupUser__c allocationGroupUserRec : (List<AllocationGroupUser__c>)newList){
            Id recordId = allocationGroupUserRec.Id ;
            newAGUserMap.put(recordId, allocationGroupUserRec);
            oldAGUserMap.put(recordId, (AllocationGroupUser__c)oldMap.get(recordId));
        }
        AllocationGroupUserService.updatedAllocationGroupUsers(newAGUserMap,oldAGUserMap);
    }

}