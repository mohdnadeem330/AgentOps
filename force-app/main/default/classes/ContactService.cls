public with sharing class ContactService {
    

    public static Map<String,Contact> getAgentsByName(Set<String> agentNames) {   

        Map<String,Contact> agentNameMap = new Map<String,Contact>();                  
        for(Contact agentRecord : [SELECT Id, Name FROM Contact WHERE Name In : agentNames]){
            agentNameMap.put(agentRecord.Name,agentRecord);
        }       
        return agentNameMap;
    }

    public static Map<String,Contact> getContactsByAccountId(Set<Id> accountsIds) {   

        Map<String,Contact> contactMap = new Map<String,Contact>();                  
        for(Contact contactRecord : [SELECT AccountId, AnnualIncome__c, Birthdate, Company__c, Id, Name, Account.OwnerId FROM Contact WHERE AccountId In : accountsIds]){
            contactMap.put(contactRecord.AccountId,contactRecord);
        }
        return contactMap;
    }

    @AuraEnabled
    public static string getAccountId(Id contactId){
        try {
            Contact getContactRec =[SELECT AccountId,Id FROM Contact WHERE Id =: contactId];
            string accountId=getContactRec.AccountId;
                return accountId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
   




    /*
    *Create Contact By Agency Admin
    */
    public static List<Contact> createAgencyContact(List<AgencyTeam__c> agencyTeam, Id accountId, String brokerType) {

        List<Contact> contactToBeInsert = new List<Contact>();

        System.debug('Point: agencyTeam: '+agencyTeam);

        for(AgencyTeam__c agency : agencyTeam){
            
            Contact newContact = new Contact();

            if (agency.Name.split(' ').size() == 2) {
                newContact.FirstName = agency.Name.split(' ')[0];
                newContact.LastName = agency.Name.split(' ')[1];
            } else if (agency.Name.split(' ').size() == 1) {
                newContact.LastName = agency.Name;
            } else {
                newContact.FirstName = agency.Name.split(' ')[0];
                newContact.MiddleName = agency.Name.split(' ')[1];
                newContact.LastName = agency.Name.split(' ')[2];
            }
            newContact.AccountId = accountId;
            newContact.Title = agency.Title__c;
            newContact.Email = agency.EmailAddress__c;
            newContact.EmailAddress__c = agency.EmailAddress__c;

            if(agency.MobileNumber__c != null){
                newContact.MobileCountryCode__c = agency.MobileNumber__c.split(' ').size() > 1 ? agency.MobileNumber__c.split(' ')[0] : '';
                newContact.MobilePhone__c = agency.MobileNumber__c.split(' ').size() > 1 ? agency.MobileNumber__c.split(' ')[1] : '';
                newContact.MobilePhone = agency.MobileNumber__c.replaceAll('(\\s+)', '');
                newContact.Phone = agency.MobileNumber__c.replaceAll('(\\s+)', '');
            }
            
            if(agency.ServiceRequest__r.BrokerManager__c != null){
                newContact.OwnerId = agency.ServiceRequest__r.BrokerManager__c;
            }

            newContact.MailingCountry = agency.Country__c;
            newContact.BrokerType__c = brokerType;
            newContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();

            contactToBeInsert.add(newContact);
        }
        insert contactToBeInsert;   
        return contactToBeInsert;       
    }

    public static Map<Id, Contact> getAgencyAdminContactsFromRelatedToAccount(Map<Id, Account> accountsMap){
        Map<ID, Contact>  contactsMap = new Map<ID, Contact>([SELECT Id, AccountId, Account.ParentId from Contact WHERE BrokerType__c =: Constants.AGENCY_ADMIN AND AccountId in :accountsMap.keySet()]);
        return  contactsMap ;
    }

    public static Map<Id,Contact> getAllContactsByAccountId(Set<Id> accountsIds) {   

        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id,AccountId, Name FROM Contact WHERE AccountId In : accountsIds]);                  
        return contactMap;
    }

    @InvocableMethod( label='ResetPassword')
    public static  void resetPassword(List<Id> recordId) {
    try{  
    User users=UserService.getUserDetails(recordId);
    Id userId= users.Id;

    System.resetPassword(userId, true);
    
    }catch(Exception e){
    System.debug('Exception>>>>>>>'+ e);
    }
}

}