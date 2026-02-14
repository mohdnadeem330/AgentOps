public class BlockedDuplicateBrokerQueueable implements Queueable {
    Map<Id,Contact> mapContactFinal = new Map<Id,Contact>();
    
    public BlockedDuplicateBrokerQueueable(Map<Id,Contact> mapContactFinal) {
        this.mapContactFinal = mapContactFinal;
    }
    
    public void execute(QueueableContext context){
        Map<Id,User> mapUserRecords = new Map<Id,User>([SELECT Id,ContactId FROM User WHERE ContactId IN : mapContactFinal.keySet()]);
        List<UserLogin> listUsersToUpdate = new List<UserLogin>();
        for(UserLogin eachUser : [SELECT Id,UserId,isFrozen FROM UserLogin WHERE UserId IN : mapUserRecords.keySet()]){
            eachUser.isFrozen = true; listUsersToUpdate.add(eachUser);
        }
        if(!listUsersToUpdate.isEmpty() && !Test.isRunningTest()){Database.update(listUsersToUpdate, false);
        }
    } 
}