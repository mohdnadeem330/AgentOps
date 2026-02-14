/**********************************************************************************************************************
* Name               : UnitSearchController                                                       
* Description        : 
* Usage              :                                                       
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class UnitSearchController {

  Public static boolean isManageInventory = false;
  @AuraEnabled(cacheable=false)
  public static list<String> getBlockedReasonsByUserRole(String userProfile){

    list<String> blockedReasonsPickListValues = new list<String>();
    String blockedReasons = Label.BlockedReasons;
    List<String> blockedReasonsSplitted = blockedReasons.split(',');
    for (String str : blockedReasonsSplitted){
      if (str != 'MEMO') {
        blockedReasonsPickListValues.add(str);
      }
    }

    if (userProfile.contains(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR)) {
      String restrictedBlockedReasons = Label.RestrictedBlockedReasons;
      List<String> restrictedBlockedReasonsSplitted = restrictedBlockedReasons.split(',');
      for (String str : restrictedBlockedReasonsSplitted){
        blockedReasonsPickListValues.add(str);
      }
    }
    return blockedReasonsPickListValues;
  }
  
  @AuraEnabled(cacheable=false)
  public static Boolean updateUnit(String allocationGroup, String assignedTo, String propertyStatus, String blockedReason, List<String> idList, String comments, String blockedBy, String blockedDate) {

    List<Unit__c> unitList = new List<Unit__c>();
List<Unit_Assignment__c> a =[SELECT Id,Unit__c,Status__c
                                                    FROM Unit_Assignment__c 
                                                    where Unit__c IN: idList and Unit_Release_Date__c = null];

List<Unit_Assignment__c> rejectUAfromManagerInventroy = new List<Unit_Assignment__c>();
    //code added by Noor
    for( Unit_Assignment__c ua :a  ){

      if(ua.Status__c == 'Pending approval'){
        ua.Status__c = 'Rejected';
      }
      ua.Unit_Release_Date__c = System.now();
      ua.Unit_Released_From__c = 'Manage Inventory';
      ua.Unit_Released_By__c = UserInfo.getUserId();   
      rejectUAfromManagerInventroy.add(ua);
    }
    update rejectUAfromManagerInventroy;
        
    for(Integer i = 0; i<idList.size(); i++){
        Unit__c unitRecord = new Unit__c();
        // ASF-3725 changes (Unit Assignment) : Bashim
        unitRecord.RelatedOpportunity__c = null;
        unitRecord.Id = idList[i];
      if (String.isNotEmpty(blockedReason)) {
          unitRecord.BlockedReason__c= blockedReason;
      }
      if (String.isNotEmpty(blockedDate)) {
        if (blockedDate == 'null') {
            unitRecord.BlockedDate__c = null;
        }else {
            unitRecord.BlockedDate__c= System.now();
        }
      }
      if (String.isNotEmpty(comments)) {
      unitRecord.BlockedComments__c= comments;
      }
      if (String.isNotEmpty(blockedBy)) {
        if (blockedBy == 'null') {
          unitRecord.BlockedBy__c = null;
        }else {
          unitRecord.BlockedBy__c = blockedBy;
        }
      }
      if (String.isNotEmpty(propertyStatus)) {
      unitRecord.Status__c = propertyStatus;
      }
      if (String.isNotEmpty(allocationGroup)) {
        if (allocationGroup == 'null') {
          unitRecord.AllocationGroup__c = null;
        }else {
          unitRecord.AllocationGroup__c = allocationGroup;
        }
      }
      if (String.isNotEmpty(assignedTo)) {
        if (assignedTo == 'null') {
          unitRecord.AssignedToUser__c = null;
        }else {
          unitRecord.AssignedToUser__c = assignedTo;
        }
      }
      unitList.add(unitRecord);
      }
      isManageInventory = true;
      update unitList;
      return true;     
    }
  }