public without sharing class ContactUsController {
    
    @AuraEnabled(cacheable=false)
    public static List<User> getUsersQuery(String query) {
        List<User> records = Database.query(query);
        return records;
    }
    
     @AuraEnabled
    public static List<Contact> getSodicTeamMembers() {
        String SODICAccName = System.Label.SOIDCAccountName;
        return [Select Id,FirstName,LastName,Email,MobilePhone,Title,Description from Contact WHERE AgentStatus__c = 'Active' AND RecordType.Name = 'Broker Agent' AND Account.Name =: SODICAccName];
    }
    
    @AuraEnabled(cacheable=false)
    public static List<User> getBMandSMTeam() {
        // Updated by Moh Sarfaraj for BPE-191
        List<User> records = [SELECT Title, Region__c, FirstName, LastName, RoleName__c, Email, MobilePhone, 
                              FullPhotoUrl, ProfileName__c, IsActive, Team__c, ShowOnBrokerPortal__c, BrokerTitle__c
                              //, KnownLanguages__c
                              FROM User 
                              WHERE  HideFromBrokerPortalContactUs__c = False 
                              AND ((IsActive = True AND (RoleName__c IN ('Head of Broker Management', 'Head of Sales - AUH', 'Head of Sales - DXB', 'Associate Director of Sales', 
                                                                        'LSQ - Sales Manager North','LSQ - Sales Manager South')
                                                        OR ProfileName__c IN (  'Sales Manager', 'Broker Manager', 'Resale Relationship Manager' )) ) )];
        return records;
    }

    @AuraEnabled(cacheable=false)
    public static List<User> getloggedInUserDetails() {

        List<User> records = [Select Id, AccountId, Account.OwnerId, Account.Owner.FirstName, Account.Owner.LastName, Account.Owner.RoleName__c,
                Account.Owner.Email, Account.Owner.MobilePhone, Account.Owner.FullPhotoUrl,Account.Owner.ProfileName__c, Account.BillingState,Account.BillingCountry, Region__c
                From User WHERE Id=:UserInfo.getUserId()];

        return records;
    }

    // Added By Moh Sarfaraj for BPE-8 
    @AuraEnabled(cacheable=true)
    public static List<String> getRegionPicklist() {
        List<Schema.PicklistEntry> entries = User.Region__c.getDescribe().getPicklistValues();
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : entries) {
            values.add(entry.getValue());
        }
        return values;
    }
}