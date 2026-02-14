public with sharing class AccountChangeOwnerController {
    
    @AuraEnabled
    public static List<Object> getRecordsByName(String objectName, String searchFor, String additionalWhereClause) {
        String queryString = 'SELECT Id, Name FROM ';
        queryString += String.escapeSingleQuotes(objectName) + ' WHERE Name Like \'%' + String.escapeSingleQuotes(searchFor) + '%\'';

        if(additionalWhereClause != null && String.isNotEmpty(additionalWhereClause)){
            queryString += ' AND ' + additionalWhereClause;
        }
        return Database.query(queryString);
    }

    @AuraEnabled
    public static List<Object> getRecordsRegionByName(String objectName, String searchFor, String additionalWhereClause) {
        String queryString = 'SELECT Id, Name, AgencyRegion__c FROM ';
        queryString += String.escapeSingleQuotes(objectName) + ' WHERE Name Like \'%' + String.escapeSingleQuotes(searchFor) + '%\'';

        if(additionalWhereClause != null && String.isNotEmpty(additionalWhereClause)){
            queryString += ' AND ' + additionalWhereClause;
        }
        return Database.query(queryString);
    }

    @AuraEnabled
    public static List<Account> getAllAccountsRecords(List<String> searchFor) {
        
        String queryString = 'Select Id, Name, AccountNumber__c, OwnerId, Owner.Name, AgencyRegion__c, RegistrationNumber__c From Account Where RecordType.Name = \'Broker Agency\'';
        for (String str : searchFor) {
            queryString += ' AND ' + str;
        }
        return Database.query(queryString);
    }

    @AuraEnabled
    public static void updateSelectedAccounts(List<Map<String, Object>> selectedAccounts, String userId) {
        
        List<Account> accountsToUpdate = new List<Account>();

        for(Map<String, Object> account: selectedAccounts) {
            String accountId = (String)account.get('id');

            Account accountRecord = new Account(Id= accountId, OwnerId= userId);
            accountsToUpdate.add(accountRecord);
        }

        if(accountsToUpdate != null && accountsToUpdate.size() > 0){
            update accountsToUpdate;
        }
    }
}