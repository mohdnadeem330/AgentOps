public with sharing class AccountRelationshipService {
  public static List<AccountRelationship__c> getAccountRelationshipType(Set<Id> arId) {
      List<AccountRelationship__c> relType=[SELECT Id ,RelatedAccount__c,RelatedAccount__r.Name,RelationshipType__c,RelatedAccount__r.NationalIdNumber__pc, RelatedAccount__r.IsPersonAccount, RelatedAccount__r.PassportNumber__pc, RelatedAccount__r.RegistrationNumber__c from AccountRelationship__c WHERE Id IN: arId ];
      return relType;
  }

  public static List<AccountRelationship__c> getAccountRelationshipFromAccountId(Id accountId) {
      List<AccountRelationship__c> relType = [SELECT Id, Name, Account__c, Account__r.Name, RelatedAccount__c, RelatedAccount__r.Name, 
                                                  RelationshipType__c FROM AccountRelationship__c WHERE Account__c =: accountId];
      return relType;
  }
}