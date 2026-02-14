global class BatchToUpdateAgencyStatus implements Schedulable, Database.Batchable<sObject>{

    global void execute(SchedulableContext ctx) {
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        String query = 'SELECT Id,CurrentAgencyStatus__c, LastSalesOrderClosureDate__c, BrokerAgencyStatus__c, DateOfRegistration__c FROM Account Where DateOfRegistration__c != null AND RecordTypeId =:recordTypeId';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> actlist){
        List<Account> accountlistToUpdate = new List<Account>();
        
        for(Account account: actlist){
            if(account.BrokerAgencyStatus__c != account.CurrentAgencyStatus__c) {
                account.PreviousAgencyStatus__c  = account.CurrentAgencyStatus__c;
                account.CurrentAgencyStatus__c   = account.BrokerAgencyStatus__c;
                accountlistToUpdate.add(account);
            }
        }
        if(!accountlistToUpdate.isEmpty()){
            update accountlistToUpdate;
        }
    }
    global void finish(Database.BatchableContext BC){

    }
}