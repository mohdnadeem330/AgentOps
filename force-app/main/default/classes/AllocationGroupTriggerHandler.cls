public with sharing class AllocationGroupTriggerHandler extends TriggerHandler{

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {

        //---- Create the public group and update the allocation group records with respective Ids
        AllocationGroupService.updateAllocationGroup(AllocationGroupService.createPublicGroup(newList));

    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
        Set<Id> reactiveAllocationGroupIds = new Set<Id>();
        Set<Id> endedAllocationGroupIds = new Set<Id>();
        
        for(AllocationGroup__c allocationGroupRec : (List<AllocationGroup__c>) newList){
            AllocationGroup__c oldRec = (AllocationGroup__c)oldMap.get(allocationGroupRec.Id);
            //---- When Group is Reactivated add users to the group
            if(allocationGroupRec.EndDate__c >= Date.Today() && oldRec.EndDate__c < Date.Today()){
                reactiveAllocationGroupIds.add(allocationGroupRec.id);
            }
            //---- When Group is end date is updated
            else if(allocationGroupRec.EndDate__c < Date.Today() && oldRec.EndDate__c >= Date.Today()){
                endedAllocationGroupIds.add(allocationGroupRec.id);
            }
        }   
        
        //----- Get Allocation Group users
        if((reactiveAllocationGroupIds != null && !reactiveAllocationGroupIds.isEmpty()) || (endedAllocationGroupIds != null && !endedAllocationGroupIds.isEmpty())){
            AllocationGroupUserService.AllocationGroupUsers allocationGroupUserIds = AllocationGroupUserService.getAllocationGroupUsers(reactiveAllocationGroupIds,endedAllocationGroupIds);
            System.debug(allocationGroupUserIds.activeUserIds+'**activeUserIds**'+allocationGroupUserIds.removeUsers);
            if(allocationGroupUserIds.activeUserIds !=null && allocationGroupUserIds.activeUserIds.size()>0)
                AllocationGroupUserService.validateAllocationGroupEndDate(allocationGroupUserIds.activeUserIds);
            if(allocationGroupUserIds.removeUsers !=null && allocationGroupUserIds.removeUsers.size()>0)
                AllocationGroupUserService.deletedAllocationGroupMembers(allocationGroupUserIds.removeUsers);
        }

    }
}