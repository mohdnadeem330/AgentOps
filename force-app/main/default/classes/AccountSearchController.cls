public with sharing class AccountSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Case> searchCases(String accountName) {
        if (String.isBlank(accountName)) {
            return new List<Case>();
        }
        String searchTerm = '%' + accountName + '%';
        return [SELECT Id, RecordType.Name, Account.Name, Status, Project__c, Legal_Case_Category__c, Owner.Name, CaseNumber, Batch__c, Unit__c, Unit__r.Id, Unit__r.Name, Unit_text__c
                FROM Case 
                WHERE RecordType.DeveloperName = 'Corporate_Legal'
                AND Account.Name LIKE :searchTerm];
    }
}