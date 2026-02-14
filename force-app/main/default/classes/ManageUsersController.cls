public with sharing class ManageUsersController { 

  @AuraEnabled(cacheable=false)
  public static list<String> getUserRoles(){
    
    list<String> userRolesPickListValues = new list<String>();
    String userRoles = Label.SalesManagersUsersRoles;
    List<String> userRolesSplitted = userRoles.split(',');
    for (String str : userRolesSplitted){
      userRolesPickListValues.add(str);
    }
    return userRolesPickListValues;
  }

  @AuraEnabled(cacheable=false)
  public static Boolean updateAllocationGroupUser( List<String> idList, Date startDate,  Date endDate) {

    List<AllocationGroupUser__c> allocationGroupUserList = new List<AllocationGroupUser__c>();
    for(Integer i = 0; i<idList.size(); i++){
      AllocationGroupUser__c allocationGroupUserRecord = new AllocationGroupUser__c();
      allocationGroupUserRecord.Id = idList[i];
      allocationGroupUserRecord.StartDate__c = startDate;
      allocationGroupUserRecord.EndDate__c = endDate;
      allocationGroupUserList.add(AllocationGroupUserRecord);
    }
    update allocationGroupUserList;
    return true;     
  }

  @AuraEnabled(cacheable=false)
  public static Boolean removeAllocationGroupUser(List<Id> usersList) {
      
    List<AllocationGroupUser__c> allocationGroupUserList = new List<AllocationGroupUser__c>();
    for (AllocationGroupUser__c allocationGroupUserRecordTemp : [select id, StartDate__c from AllocationGroupUser__c where Id IN:usersList]) {
      AllocationGroupUser__c allocationGroupUserRecord = new AllocationGroupUser__c();
      allocationGroupUserRecord.Id = allocationGroupUserRecordTemp.Id;
      allocationGroupUserRecord.EndDate__c = System.today() -1;
      if (allocationGroupUserRecordTemp.StartDate__c >= System.today()) {
        allocationGroupUserRecord.StartDate__c = System.today() -1;
      }
      allocationGroupUserList.add(AllocationGroupUserRecord);
    }
    update allocationGroupUserList;
    return true;     
  }

  @AuraEnabled(cacheable=false)
  public static Boolean CreateAllocationGroupUser( List<String> idList, Date StartDate,  Date EndDate, String allocationGroupId) {
        
    List<AllocationGroupUser__c> allocationGroupUserList = new List<AllocationGroupUser__c>();
    
    for(Integer i = 0; i<idList.size(); i++){
      
      AllocationGroupUser__c AllocationGroupUserRecord = new AllocationGroupUser__c();
      allocationGroupUserRecord.User__c = idList[i];
      allocationGroupUserRecord.AllocationGroup__c = allocationGroupId;
      allocationGroupUserRecord.StartDate__c = startDate;
      allocationGroupUserRecord.EndDate__c = endDate;
      allocationGroupUserList.add(AllocationGroupUserRecord);
    }
    insert allocationGroupUserList;
    return true;     
  }
}