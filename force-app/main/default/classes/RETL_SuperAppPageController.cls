public without sharing class RETL_SuperAppPageController {
    @AuraEnabled(cacheable=true)
    public static User getCurrentUser() {
        return [
            SELECT Id, Name, Email, UserType, Profile.Name, Profile.UserLicense.Name, ContactId, Contact.AccountId,Contact.RecordType.Name, Contact.Account.CustomerVertical__c,
                Contact.FirstName, Contact.MiddleName, Contact.LastName, Contact.Account.Name, Contact.Account.Role__c, Contact.Account.Email__c, Contact.Account.MobileCountryCode__c,
                Contact.Account.MobileNumber1__c, Contact.Account.MobileNumber__c, Contact.Account.BillingStreet, Contact.Account.BillingCity, Contact.Account.BillingPostalCode, Contact.Account.BillingState, Contact.Account.RegistrationIssueDate__c,
                Contact.Account.RegistrationNumber__c, Contact.Account.RegistrationExpiryDate__c, Contact.Account.PlaceOfRegistration__c, 
                Contact.Account.UAEVATRegisterNumber__c, Contact.Account.P_O_Box__c, Contact.Account.Fax, Contact.Salutation, Contact.MobileCountryCode__c, Contact.MobilePhone__c,
                Contact.Email, Contact.MailingStreet, Contact.MailingCity, Contact.MailingPostalCode, Contact.CountryOfResidence__c, Contact.CustomerLocation__c, Contact.NationalIdExpiryDate__c,
                Contact.NationalIdNumber__c, Contact.PassportNumber__c, Contact.PlaceofIssue__c, Contact.PassportIssueDate__c, Contact.PassportExpiryDate__c, Contact.RETL_Visa_Issue_Location__c,
                Contact.VisaUIDNo__c, Contact.RETL_Visa_Issue_Date__c, Contact.VisaExpiryDate__c, Contact.Nationality__c, Contact.MobilePhone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
    }
    public class VerticalInfoWrapper {
        @AuraEnabled public String customerVerticals;
        @AuraEnabled public Boolean hasUser;
        @AuraEnabled public String existingProfile;
        @AuraEnabled public List<String> existingPermissions;
    }
    
    @AuraEnabled(cacheable=true)
    public static VerticalInfoWrapper getVerticalInfo(Id contactId) {
        
        VerticalInfoWrapper response = new VerticalInfoWrapper();
        
        Contact c = [
            SELECT Id, Account.CustomerVertical__c
            FROM Contact
            WHERE Id = :contactId
        ];
        
        response.customerVerticals = c.Account.CustomerVertical__c;
        
        List<User> users = [
            SELECT Id, Profile.Name
            FROM User
            WHERE ContactId = :contactId
            LIMIT 1
        ];
        
        response.hasUser = !users.isEmpty();
        
        if (response.hasUser) {
            response.existingProfile = users[0].Profile.Name;
            
            List<PermissionSetAssignment> ps = [
                SELECT PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :users[0].Id
            ];
            
            response.existingPermissions = new List<String>();
            for (PermissionSetAssignment p : ps) {
                response.existingPermissions.add(p.PermissionSet.Name);
            }
        }
        
        return response;
    }
    @AuraEnabled
    public static RETL_Contact_role__c getCurrentUserContactRole( String contactId, string accountId) {
        List<RETL_Contact_role__c> contactRole =  [
            SELECT Id, RETL_Contact__c, RETL_Account_Name__c, RETL_Contact_role__c 
            FROM RETL_Contact_role__c
            WHERE RETL_Contact__c =: contactId AND RETL_Account_Name__c =:accountId 
        ];
        if( !contactRole.isEmpty()){
            return contactRole[0];
        }
        return new RETL_Contact_role__c();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getDocument(String contactId, String accountId){
        system.debug('contactId'+contactId + ' accountId'+accountId);
        
        List<Document__c> docList = [
            SELECT Id, Name, Account__c, Contact__c, DocumentType__c, CreatedDate
            FROM Document__c
            WHERE Account__c = :accountId 
            OR Contact__c = :contactId
            ORDER BY DocumentType__c, CreatedDate DESC
        ];
        
        // Map to store only latest record per DocumentType
        Map<String, Document__c> latestDocByType = new Map<String, Document__c>();
        
        for (Document__c doc : docList) {
            if (!latestDocByType.containsKey(doc.DocumentType__c)) {
                latestDocByType.put(doc.DocumentType__c, doc);
            }
        }
        
        // Final list of latest docs
        List<Document__c> latestDocs = latestDocByType.values();
        
        Map<Id, DocumentWrapper> mapDoc = new Map<Id, DocumentWrapper>();
        
        for(Document__c d : latestDocs){
            DocumentWrapper w = new DocumentWrapper();
            w.docId = d.Id;
            w.documentType = d.DocumentType__c;
            w.label = d.Name;    
            mapDoc.put(d.Id, w);
        }
        
        
        // Fetch ContentDocumentLink for these Document__c records
        if( !mapDoc.isEmpty()){
            List<ContentDocumentLink> links = [
                SELECT Id, ContentDocumentId, LinkedEntityId,
                ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :mapDoc.keySet()
            ];
            if( !links.isEmpty()){
                for(ContentDocumentLink link : links){
                    if(mapDoc.containsKey(link.LinkedEntityId)){
                        mapDoc.get(link.LinkedEntityId).fileName = link.ContentDocument.Title;
                    }
                }
                return mapDoc.values();
            }
        }
        return new list<DocumentWrapper>();
    }
    
    public class DocumentWrapper {
        @AuraEnabled public String docId;
        @AuraEnabled public String documentType;
        @AuraEnabled public String fileName;  
        @AuraEnabled public String label;     
    }
    
}