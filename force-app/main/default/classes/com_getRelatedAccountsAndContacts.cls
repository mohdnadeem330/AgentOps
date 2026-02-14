public with sharing class com_getRelatedAccountsAndContacts {
    public class FlowInput {
        @InvocableVariable(required=true label='Parent Account Id')
        public Id parentAccountId;
    }

    public class FlowOutput {
        @InvocableVariable(label='Related Accounts')
        public List<Account> relatedAccounts;

        @InvocableVariable(label='Related Contacts')
        public List<Contact> relatedContacts;
    }
    
    @InvocableMethod(
        label='Get Related Accounts & Contacts'
        description='Returns Accounts and Contacts related to the given parent Account.'
    )
    public static List<FlowOutput> getRelatedForFlow(List<FlowInput> requests) {
        List<FlowOutput> results = new List<FlowOutput>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (FlowInput req : requests) {
            FlowOutput out = new FlowOutput();
            out.relatedAccounts  = new List<Account>();
            out.relatedContacts  = new List<Contact>();

            if (req.parentAccountId != null) {
                Account parentAcc = [
                    SELECT Id, Name, IsPersonAccount, RecordTypeId
                    FROM Account
                    WHERE Id = :req.parentAccountId
                    LIMIT 1
                ];

                out.relatedAccounts = getRelatedAccounts(null, parentAcc);
                out.relatedContacts = getRelatedContacts(null, parentAcc);
            }

            results.add(out);
        }

        return results;
    }

    public static List<Account> getRelatedAccounts(String accountType, Account parentAccount){
        List<Account> relatedAccounts = new List<Account>();
        if (!parentAccount.IsPersonAccount) {
    return new List<Account>();
}
        
        if (parentAccount == null || parentAccount.Id == null) {
        return relatedAccounts;
    }
        List<AccountRelationship__c> accountRelationships = [
        SELECT Id, Account__c, RelatedAccount__c,RelationshipSubType__c, RelationshipType__c
        FROM AccountRelationship__c
        WHERE RelatedAccount__c = :parentAccount.Id
                  AND RelationshipSubType__c NOT IN ('Broker', 'Owner', 'POA')

    ];
        
        Set<Id> relatedIds = new Set<Id>();
        
        for (AccountRelationship__c relationship : accountRelationships) {
        if (relationship.Account__c == parentAccount.Id && relationship.RelatedAccount__c != null) {
            relatedIds.add(relationship.RelatedAccount__c);
        } else if (relationship.RelatedAccount__c == parentAccount.Id && relationship.Account__c != null) {
            relatedIds.add(relationship.Account__c);
        }
    }
        
        if (!relatedIds.isEmpty()) {
        relatedAccounts = [
            SELECT Id, Name, PersonBirthdate
            FROM Account
            WHERE Id IN :relatedIds
        ];
    }

    return relatedAccounts;
}
    
    
    public static List <Contact> getRelatedContacts(String accountType, Account parentAccount){
           List<Contact> relatedContacts = new List<Contact>();
           Id orgAccountRT= Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();

        if (parentAccount.RecordTypeId!=orgAccountRT) {
    return new List<Contact>();
}
        
        if (parentAccount == null || parentAccount.Id == null) {
        return relatedContacts;
    }
        List<AccountContactRelation> accountContactRelationships = [
        SELECT Id, AccountId , ContactId 
        FROM AccountContactRelation 
        WHERE AccountId = :parentAccount.Id
        
    ];
        
        Set<Id> relatedIds = new Set<Id>();
        
        for (AccountContactRelation relationship : accountContactRelationships) {
        if (relationship.AccountId == parentAccount.Id && relationship.ContactId != null) {
            relatedIds.add(relationship.ContactId);
        } 
    }
        
        if (!relatedIds.isEmpty()) {
        relatedContacts = [
            SELECT Id, Name, FirstName, LastName,Birthdate
            FROM Contact
            WHERE Id IN :relatedIds
        ];
    }

    return relatedContacts;
    }
    
    /*
    public class AccountResult {
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public Id childAccountId;          
        @AuraEnabled public Id accountRelationshipId;   
    }

    public class ContactResult {
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public Id contactId;              
        @AuraEnabled public Id accountContactRelationId;
    }


    @AuraEnabled
    public static AccountResult createAccountAndRelation(
        Id parentAccountId,
        String childAccountName,
        String accountRelationshipType,     
        String accountRelationshipSubType   
    ) {
        if (parentAccountId == null) {
            throw new AuraHandledException('Parent Account Id is required.');
        }
        if (String.isBlank(childAccountName)) {
            throw new AuraHandledException('Child Account Name is required.');
        }

        AccountResult result = new AccountResult();
        result.parentAccountId = parentAccountId;

        try {
            // 1) Create child account
            Account childAcc = new Account();
            childAcc.Name = childAccountName;
            insert childAcc;

            result.childAccountId = childAcc.Id;

            AccountRelationship__c ar = new AccountRelationship__c();
            ar.Account__c       = parentAccountId;
            ar.RelatedAccount__c = childAcc.Id;

            if (!String.isBlank(accountRelationshipType)) {
                ar.RelationshipType__c = accountRelationshipType;
            }
            if (!String.isBlank(accountRelationshipSubType)) {
                ar.RelationshipSubType__c = accountRelationshipSubType;
            }

            insert ar;
            result.accountRelationshipId = ar.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error creating Account & relationship: ' + e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static AccountResult relateExistingAccount(
        Id parentAccountId,
        Id existingAccountId,
        String accountRelationshipType,
        String accountRelationshipSubType
    ) {
        if (parentAccountId == null) {
            throw new AuraHandledException('Parent Account Id is required.');
        }
        if (existingAccountId == null) {
            throw new AuraHandledException('Existing Account Id is required.');
        }

        AccountResult result = new AccountResult();
        result.parentAccountId = parentAccountId;
        result.childAccountId  = existingAccountId;

        try {
            AccountRelationship__c ar = new AccountRelationship__c();
            ar.Account__c        = parentAccountId;
            ar.RelatedAccount__c = existingAccountId;

            if (!String.isBlank(accountRelationshipType)) {
                ar.RelationshipType__c = accountRelationshipType;
            }
            if (!String.isBlank(accountRelationshipSubType)) {
                ar.RelationshipSubType__c = accountRelationshipSubType;
            }

            insert ar;
            result.accountRelationshipId = ar.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error relating existing Account: ' + e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static ContactResult createContactAndRelation(
        Id parentAccountId,
        String contactFirstName,
        String contactLastName,
        String contactEmail,
        String contactPhone
    ) {
        if (parentAccountId == null) {
            throw new AuraHandledException('Parent Account Id is required.');
        }
        if (String.isBlank(contactLastName)) {
            throw new AuraHandledException('Contact Last Name is required.');
        }

        ContactResult result = new ContactResult();
        result.parentAccountId = parentAccountId;

        try {
            Contact c = new Contact();
            c.FirstName = contactFirstName;
            c.LastName  = contactLastName;
            c.Email     = contactEmail;
            c.Phone     = contactPhone;
            insert c;

            result.contactId = c.Id;

            AccountContactRelation acr = new AccountContactRelation();
            acr.AccountId = parentAccountId;
            acr.ContactId = c.Id;

            insert acr;
            result.accountContactRelationId = acr.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error creating Contact & relation: ' + e.getMessage());
        }

        return result;
    }


    @AuraEnabled
    public static ContactResult relateExistingContact(
        Id parentAccountId,
        Id existingContactId
    ) {
        if (parentAccountId == null) {
            throw new AuraHandledException('Parent Account Id is required.');
        }
        if (existingContactId == null) {
            throw new AuraHandledException('Existing Contact Id is required.');
        }

        ContactResult result = new ContactResult();
        result.parentAccountId = parentAccountId;
        result.contactId       = existingContactId;

        try {
            AccountContactRelation acr = new AccountContactRelation();
            acr.AccountId = parentAccountId;
            acr.ContactId = existingContactId;

            insert acr;
            result.accountContactRelationId = acr.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error relating existing Contact: ' + e.getMessage());
        }

        return result;
    }
    
     @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey, Id parentAccountId) {
        String key = (searchKey == null) ? '' : searchKey.trim();
        String likeKey = '%' + key + '%';

        List<Account> accs = [
            SELECT Id, Name, Phone
            FROM Account
            WHERE Name LIKE :likeKey
                  AND Id != :parentAccountId   
            ORDER BY Name

        ];

        return accs;
    }
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchKey, Id parentAccountId) {
        String key = (searchKey == null) ? '' : searchKey.trim();
        String likeKey = '%' + key + '%';

        List<Contact> cons = [
            SELECT Id, FirstName, LastName
            FROM Contact
            WHERE (FirstName LIKE :likeKey OR LastName LIKE :likeKey)
            ORDER BY LastName, FirstName
            
        ];

        return cons;
    }
    */
}