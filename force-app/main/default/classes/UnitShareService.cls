public without sharing class UnitShareService {
    
  /*
   * Control Unit Sharing to users
   */
   public static void shareOrUnshareUnitAccess(Map<Id,Unit__c> newUnitsMap, Map<Id,Unit__c> oldUnitsMap){
	     
       String USER_ROLE_CASA_VP = 'CASA VP';
       List<Unit__Share> unitShareListToCreate = new List<Unit__Share>();
       Map<Id,Id> unitShareToDelete = new Map<Id,Id>();
       List<Unit__c> unitListWithOwnerUpdate = new List<Unit__c>();
 
         for(Unit__c unitRecord : newUnitsMap.values()){
           Unit__c oldUnitRecord = oldUnitsMap.get(unitRecord.Id);
           System.debug(unitRecord.AssignedToUser__c+'***Status***'+unitRecord.Status__c);
           System.debug(unitRecord.AllocationGroup__c+'***Allocation Group***'+unitRecord.PublicGroupAssociated__c);
           //---- Check if the unit is assigned to different user
           if(unitRecord.Status__c == Constants.UNIT_STATUS_AVAILABLE){
               System.debug('unitRecord.AssignedToUser__c '+unitRecord.AssignedToUser__c);
               System.debug('oldUnitRecord.AssignedToUser__c '+oldUnitRecord.AssignedToUser__c);
             if(unitRecord.AssignedToUser__c !=null && ((unitRecord.AssignedToUser__c != oldUnitRecord.AssignedToUser__c) ||(unitRecord.Status__c != oldUnitRecord.Status__c))){
               unitShareListToCreate.add(UnitService.getUnitShare(unitRecord.Id,unitRecord.AssignedToUser__c,Label.PropertyEditAccess));
               //----- Remove access to previous public group
               if(oldUnitRecord.AssignedToUser__c !=null)
                 unitShareToDelete.put(unitRecord.Id,oldUnitRecord.AssignedToUser__c);
             }
            //---- Check if the allocation group has been changed
            if(unitRecord.AllocationGroup__c !=null && ((unitRecord.AllocationGroup__c != oldUnitRecord.AllocationGroup__c) ||(unitRecord.Status__c != oldUnitRecord.Status__c))){
                 unitShareListToCreate.add(UnitService.getUnitShare(unitRecord.Id,unitRecord.PublicGroupAssociated__c,Label.PropertyEditAccess));
                 //----- Remove access to previous public group
               if(oldUnitRecord.AllocationGroup__c !=null)
                 unitShareToDelete.put(unitRecord.Id,oldUnitRecord.PublicGroupAssociated__c);
            }
            //----- Remove user who locked the units for booking or reservation
            if(oldUnitRecord.LockedBy__c !=null && unitRecord.AssignedToUser__c !=null && oldUnitRecord.LockedBy__c !=unitRecord.AssignedToUser__c){
              unitShareToDelete.put(unitRecord.Id,oldUnitRecord.LockedBy__c);
            }
           }            
           //------ Check if Unit Status is Changed
           else if(unitRecord.Status__c != oldUnitRecord.Status__c){
             //----- Remove access if the unit is been booked or reserved or in progress for reservation & booking
              if(unitRecord.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS){
                if(unitRecord.LockedBy__c !=null){
                    unitShareListToCreate.add(UnitService.getUnitShare(unitRecord.Id,unitRecord.LockedBy__c,Label.PropertyEditAccess));
                }   
              }
              //---- Check if the status has been changed to blocked and remove access to blocked units
              if(unitRecord.Status__c == Constants.UNIT_STATUS_BLOCKED || unitRecord.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS){
                if(unitRecord.AssignedToUser__c !=null){
                  unitShareToDelete.put(unitRecord.Id,unitRecord.AssignedToUser__c);
                }
                if(unitRecord.AllocationGroup__c !=null){
                  unitShareToDelete.put(unitRecord.Id,unitRecord.PublicGroupAssociated__c);
                }
              }
           }
           
           //----- Check if the blocked by user has changed and has a role 'Head of Sales'
           if(oldUnitRecord.BlockedBy__c !=null && unitRecord.BlockedBy__c !=null && (unitRecord.BlockedBy__c != oldUnitRecord.BlockedBy__c) && unitRecord.BlockedByUserRoleName__c != null && (unitRecord.BlockedByUserRoleName__c.contains(Constants.USER_ROLE_HEAD_OF_SALES) || unitRecord.BlockedByUserRoleName__c.contains(USER_ROLE_CASA_VP)) ){
             unitShareListToCreate.add(UnitService.getUnitShare(unitRecord.Id,unitRecord.BlockedBy__c,Label.PropertyEditAccess));
             //unitListWithOwnerUpdate.add(new Unit__c(Id=unitRecord.Id,OwnerId=unitRecord.BlockedBy__c));
           }
           //----- When the blocked by user role is 'Head of Sales' and is not the owner then change the owner
           if(oldUnitRecord.BlockedBy__c ==null && unitRecord.BlockedBy__c !=null && unitRecord.BlockedByUserRoleName__c != null && (unitRecord.BlockedByUserRoleName__c.contains(Constants.USER_ROLE_HEAD_OF_SALES) || unitRecord.BlockedByUserRoleName__c.contains(USER_ROLE_CASA_VP) ) && unitRecord.BlockedBy__c != unitRecord.OwnerId){
             //unitListWithOwnerUpdate.add(new Unit__c(Id=unitRecord.Id,OwnerId=unitRecord.BlockedBy__c));
             unitShareListToCreate.add(UnitService.getUnitShare(unitRecord.Id,unitRecord.BlockedBy__c,Label.PropertyEditAccess));
           }
           //----- Remove Sharing to Blocked by user in case user changes
           if(oldUnitRecord.BlockedBy__c !=null && unitRecord.BlockedBy__c ==null && oldUnitRecord.BlockedByUserRoleName__c !=null && oldUnitRecord.BlockedByUserRoleName__c.contains(Constants.USER_ROLE_HEAD_OF_SALES)){
             unitShareToDelete.put(unitRecord.Id,oldUnitRecord.BlockedBy__c);
           }
           //---- Check if Allocation Group is removed
           if(oldUnitRecord.AssignedToUser__c !=null && unitRecord.AssignedToUser__c ==null){
             unitShareToDelete.put(unitRecord.Id,oldUnitRecord.AssignedToUser__c);
           }
           //---- Check if Assigned To User is removed and remove access to previous public group
           if(oldUnitRecord.AllocationGroup__c !=null && unitRecord.AllocationGroup__c ==null){
             unitShareToDelete.put(unitRecord.Id,oldUnitRecord.PublicGroupAssociated__c);
           }


         }
 
       if(unitShareToDelete != null && !unitShareToDelete.isempty()){
         System.debug(unitShareToDelete.keyset()+'***Record To Delete***'+unitShareToDelete.values());
         List<Unit__Share> unitShareListToDelete = [SELECT Id from Unit__Share where ParentId IN : unitShareToDelete.keyset() AND UserOrGroupId =: unitShareToDelete.values() AND RowCause =: Schema.Unit__Share.RowCause.Manual];
         System.debug(unitShareListToDelete.size()+'***Records To Delete***'+unitShareListToDelete);
         if(unitShareListToDelete != null && !unitShareListToDelete.isempty())
           delete unitShareListToDelete;
       }
 
       if(unitShareListToCreate != null && !unitShareListToCreate.isempty()){
         insert unitShareListToCreate ; 
       }
 
       if(unitListWithOwnerUpdate != null && !unitListWithOwnerUpdate.isempty()){
         update unitListWithOwnerUpdate ; 
       }
       
   }

  @AuraEnabled(cacheable=false)
  public static void unitApprovedByLineManager(List<MemoLines__c> memoLinesList, String owner){
    User loggedinUser = Utilities.getLoggedInUserDetail();
    for (Integer i = 0; i < memoLinesList.size(); i++) {
      Unit__c unitObj = new Unit__c();
      if(memoLinesList[i].Unit__r.Status__c == Constants.UNIT_STATUS_AVAILABLE) {
        unitObj.Id = memoLinesList[i].Unit__c;
        unitObj.Status__c = Constants.UNIT_STATUS_BLOCKED;
        unitObj.BlockedBy__c = loggedinUser.Id;
        unitObj.BlockedComments__c = 'Blocked under head of sales - Memo';
        unitObj.BlockedReason__c = 'MEMO';

        update unitObj;
      }
    }
  } 
}