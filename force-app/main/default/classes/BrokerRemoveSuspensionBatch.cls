public class BrokerRemoveSuspensionBatch implements Database.Batchable<SObject>, Schedulable, Database.stateful {
    // Batchable method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, AgencyStatus__c,SuspensionRemovalReason__c FROM Account WHERE AgencyStatus__c = 'Suspended' AND 
            RecordType.DeveloperName = 'Broker_Agency' AND SuspensionEndDate__c < TODAY
        ]);
    }

    // Batchable method
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> listAgenciesToUpdate = new List<Account>();
        for (Account eachAccount : scope) {
            eachAccount.AgencyStatus__c = 'Active';
            eachAccount.SuspensionRemovalReason__c = 'Removed Suspension from Backend via Scheduled Batch';
            eachAccount.SuspensionStartDate__c = null;
            eachAccount.SuspensionEndDate__c = null;
            eachAccount.SuspensionApprovalStatus__c = '';
            listAgenciesToUpdate.add(eachAccount);
        }
        if(!listAgenciesToUpdate.isEmpty()){
            Database.SaveResult [] updateResult = Database.update(listAgenciesToUpdate, false);
            System.debug('updateResult '+ updateResult);
        }
    }

    // Batchable method
    public void finish(Database.BatchableContext BC) {
    }

    // Scheduleable method
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BrokerRemoveSuspensionBatch());
    }
}