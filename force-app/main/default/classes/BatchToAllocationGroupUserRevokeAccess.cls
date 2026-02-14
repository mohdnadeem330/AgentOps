global class BatchToAllocationGroupUserRevokeAccess implements Schedulable ,Database.Batchable<sObject>{
    
    global void execute(SchedulableContext ctx) {
        BatchToAllocationGroupUserRevokeAccess revokeAccess = new BatchToAllocationGroupUserRevokeAccess();
        database.executeBatch(revokeAccess,200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){

        string strQuery = 'Select Id,EndDate__c,User__c,AllocationGroup__c,PublicGroupAssociated__c ,AllocationGroup__r.EndDate__c from AllocationGroupUser__c  where (EndDate__c < Today AND AllocationGroup__r.IsActive__c = true) OR AllocationGroup__r.EndDate__c < Today ';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<AllocationGroupUser__c> allocationGroupUserList){
        
        //---- Remove allocation group users from the public group so they loose access
        System.debug(allocationGroupUserList.size()+'**Allocation Group User List**'+allocationGroupUserList);
        AllocationGroupUserService.deletedAllocationGroupMembers(allocationGroupUserList);
    }
    
    global void finish(Database.BatchableContext BC){

    }
}