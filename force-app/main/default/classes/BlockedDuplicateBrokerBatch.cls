global class BlockedDuplicateBrokerBatch implements Database.Batchable<SObject>, Schedulable, Database.stateful{
    Map<Id,Contact> mapContactFinal = new Map<Id,Contact>();
    Set<String> duplicateMobileNumbers = new Set<String>();
    Set<String> accountIdSetToExclude = new Set<String>();

    public BlockedDuplicateBrokerBatch(Set<String> accountIdSetToExclude){
        this.accountIdSetToExclude = accountIdSetToExclude;
        for(AggregateResult ar : [SELECT Count(Id), MobilePhone__c mob FROM Contact WHERE MobilePhone__c != null AND 
                                  RecordType.DeveloperName = 'BrokerAgent' AND AccountId NOT IN: accountIdSetToExclude GROUP BY MobilePhone__c 
                                  HAVING Count(Id) > 1 LIMIT 2000]){

            duplicateMobileNumbers.add((String) ar.get('mob'));
        }

        for(AggregateResult ar : [SELECT Count(Id), MobilePhone__c mob FROM Contact WHERE 
                                  MobilePhone__c NOT IN :duplicateMobileNumbers AND MobilePhone__c != null AND 
                                  RecordType.DeveloperName = 'BrokerAgent' AND AccountId NOT IN: accountIdSetToExclude GROUP BY MobilePhone__c  
                                  HAVING Count(Id) > 1 LIMIT 2000 ]){

            duplicateMobileNumbers.add((String) ar.get('mob'));
        }
        
    }
    
    // Batchable method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> duplicateEmailIds = new Set<String>();

        for(AggregateResult ar : [SELECT Count(Id), Email em FROM Contact WHERE Email != null AND 
                                  RecordType.DeveloperName = 'BrokerAgent' AND AccountId NOT IN: accountIdSetToExclude GROUP BY Email 
                                  HAVING Count(Id) > 1]){

            duplicateEmailIds.add((String) ar.get('em'));
        }
                            
        return Database.getQueryLocator([
            SELECT Id, Email, MobilePhone__c, BlockedFromBackend__c, AgentStatus__c
            FROM Contact 
            WHERE AgentStatus__c = 'Active' AND (MobilePhone__c IN :duplicateMobileNumbers OR Email IN :duplicateEmailIds) AND
            RecordType.DeveloperName = 'BrokerAgent' AND AccountId NOT IN: accountIdSetToExclude
        ]);
    }

    // Batchable method
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Contact> listContactsToUpdate = new List<Contact>();
        for (Contact eachContact : scope) {
            eachContact.AgentStatus__c = 'Blocked';
            eachContact.BlockedFromBackend__c =  true;
            listContactsToUpdate.add(eachContact);
            mapContactFinal.put(eachContact.Id, eachContact);
        }
        if(!listContactsToUpdate.isEmpty()){
            Database.SaveResult [] updateResult = Database.update(listContactsToUpdate,false);
            System.debug('updateResult '+ updateResult);
        }
    }

    // Batchable method
    public void finish(Database.BatchableContext BC) {
       System.enqueueJob(new BlockedDuplicateBrokerQueueable(mapContactFinal));
    }

    // Scheduleable method
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BlockedDuplicateBrokerBatch(new Set<String>()));
    }
}