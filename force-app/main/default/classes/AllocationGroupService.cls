public without sharing class AllocationGroupService {

    /*
    * Get Active Allocation Group Names
    */
    public static Set<String> getAllocationGroupNames(){
        Set<String> allocationGroupNames = new Set<String>();
        for(AllocationGroup__c allocationGroup :getActiveAllocationGroup()){
            allocationGroupNames.add(allocationGroup.Name);
        }
        return allocationGroupNames ; 
    }

    /*
    * Get Active Allocation Group Codes
    */
    public static Set<String> getAllocationGroupCodes(){
        Set<String> allocationGroupCodes = new Set<String>();
        for(AllocationGroup__c allocationGroup :getActiveAllocationGroup()){
            allocationGroupCodes.add(allocationGroup.AllocationGroupCode__c);
        }
        return allocationGroupCodes ; 
    }
    
    /*
    * Get all Active Allocation Groups
    */
    public static List<AllocationGroup__c> getActiveAllocationGroup(){
        return [SELECT Id,Name,AllocationGroupCode__c,IsActive__c FROM AllocationGroup__c WHERE IsActive__c =true]; 
    }


    /*
    * Create Public Groups for Allocation Group
    */
    public static Map<Id,Group> createPublicGroup(List<AllocationGroup__c> allocationGroupList){

        List<Group> newPublicGroupList = new List<Group>();
        Map<Id,Group> allocationGroupPublicGroupRecMap = new Map<Id,Group>();

        for(AllocationGroup__c allocationGroupRec : allocationGroupList){
            Group groupRecord = new Group();
            String groupName = allocationGroupRec.Id+'_'+allocationGroupRec.Name ;
            if(groupName.length()>40){
                groupName = allocationGroupRec.Id+'_'+allocationGroupRec.AllocationGroupCode__c ;
            }
            groupRecord.Name = groupName ;
            newPublicGroupList.add(groupRecord) ;
            allocationGroupPublicGroupRecMap.put(allocationGroupRec.Id,groupRecord);
        }

        if(newPublicGroupList != null && !newPublicGroupList.isempty()){
            insert newPublicGroupList ; 
        }
        return allocationGroupPublicGroupRecMap ;
    }

    /*
    * Update Allocation Group with Public Group Id
    */
    public static void updateAllocationGroup(Map<Id,Group> allocationGroupPublicGroupRecMap){
        List<AllocationGroup__c> allocationGroupList = new List<AllocationGroup__c>();

        for(Id recordId : allocationGroupPublicGroupRecMap.keySet()){
            AllocationGroup__c allocationGroupRec = new AllocationGroup__c(Id=recordId);
            allocationGroupRec.PublicGroupAssociated__c = allocationGroupPublicGroupRecMap.get(recordId).Id ; 
            allocationGroupList.add(allocationGroupRec);
        }

        if(allocationGroupList !=null && !allocationGroupList.isEmpty()){
            update allocationGroupList ;
        }
    }

    @AuraEnabled(cacheable=false)
      public static List<AllocationGroup__c> getAllocationGroupQuery(String query) {
      List<AllocationGroup__c> records = Database.query(query);
      return records;
  }

  @InvocableMethod(label='Add the User to the Group in future' description='Add the Allocation Grouo User to the Group to access the Unit')
    public static void addAllocationGroupUserToGroup(List<Id> allocationGroupUserIds){
        //---- If the user is not added to public group, to be added
        Set<Id> allocationGroupUserIdSet = new Set<Id>();
        try{   
            allocationGroupUserIdSet.addAll(allocationGroupUserIds) ;
            Map<Id,Set<Id>> publicGroupUserMap = AllocationGroupUserService.getPubliGroupUserMap(allocationGroupUserIdSet);
            if(!publicGroupUserMap.isEmpty())
                AllocationGroupUserService.addUsersToPublicGroup(publicGroupUserMap);
                
        }catch(Exception ex){
            LoggerService.Save( LoggerService.addApexLog(ex,'AllocationGroupService','Add the Allocation Group Service User to the Public Group','addAllocationGroupUserToGroup') );
        }
    }

}