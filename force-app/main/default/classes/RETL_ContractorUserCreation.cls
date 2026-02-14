/**
Class       : RETL_ContractorUserCreation
Author      : 
Description : This class is accessed from RETL_PortalContactCreation 
TestClass   : RETL_ContractorUserCreationTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              26/09/25           Initial Version 
****************************************************************************************************************/
public without sharing class RETL_ContractorUserCreation {
    @AuraEnabled(cacheable=true)
    public static Contact fetchCustomerVertical(String contactId){
        List<Contact> contactObj = [SELECT Id, Account.CustomerVertical__c FROM Contact WHERE Id = :contactId   LIMIT 1];
        system.debug('contactObj--'+contactObj);
        return contactObj[0];
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
    public static void createPortalUser( Id contactId, Boolean duplicate, String verticals) {
        
        List<Contact> contactObj = [SELECT Id, Email,Firstname,AccountId, LastName, MobilePhone,RecordTypeId, Account.CustomerVertical__c FROM Contact WHERE Id = :contactId  LIMIT 1];
        system.debug('contactObj--'+contactObj);
        List<User> existingUser = [ Select Id, ContactId from User Where ContactId =: contactId Limit 1];
        List<String> verticalList = (List<String>) JSON.deserialize(verticals, List<String>.class);
        System.debug('verticalList --> ' + verticalList);
        String profileName;
        List<String> pmList = new List<String>();
        List<PermissionSet> retailTenantPermission  = new List<PermissionSet>();
        
        if (!contactObj.isEmpty()  && existingUser.isEmpty()) {
            if (verticalList.size() > 1) {
                profileName = Label.DM_RequestorPortalProfile;
                pmList.add('Retail_Contractor_Permission');
            } else {
                // Only one selected — Retail or District Management
                if (verticalList[0] == 'Retail') {
                    profileName = Label.Retail_Contractor_Profile;
                    pmList.add('Retail_Contractor_Permission');
                } else {
                    profileName = Label.DM_RequestorPortalProfile;
                }
            }
            if(!pmList.isEmpty()){
                retailTenantPermission = [SELECT Id, Name FROM PermissionSet WHERE Name IN :pmList ]; 
            }
            contactObj[0].ownerId = UserInfo.getUserId();
            Update contactObj[0];
            Account acc = new Account(Id=contactObj[0].AccountId);
            acc.ownerId = UserInfo.getUserId();
            Update acc;
            //String profileName = customerVertical.Contains(';')?Label.DM_RequestorPortalProfile:Label.Retail_Contractor_Profile;
            //String permSetName = Label.Retail_Tenant_Portal_Permission_Set;// remove this and create seperete permission set
            
            //pmList.add(permSetName);
            Profile portalProfile = [SELECT Id, name FROM Profile WHERE Name  =: profileName]; 
            
            
            Organization org = Utilities.getOrganizationDetails();
            Boolean isSandbox  = org.IsSandbox;
            List<String> emailSplit = contactObj[0].Email.split('@');
            String queryString = emailSplit[0]+'%';
            string Uname = '';
            if(!duplicate){
                list<User> userList = [Select Id from User where Username LIKE :queryString];
                
                if(userList.size()>0){
                    Uname = emailSplit[0]+string.valueOf(userList.size()==1?userList.size():userList.size()+1)+'@aldar.com.dm';
                }else{
                    Uname = emailSplit[0]+'@aldar.com.dm';
                }  
            }else{
                Uname = emailSplit[0]+string.valueOf(Integer.valueOf(Math.random() * 100))+'@aldar.com.dm';
            }
            
            try {  
                User portalUser = new User(
                    Username = Uname,
                    ContactId = contactObj[0].Id,
                    ProfileId = portalProfile.Id,
                    Alias = contactObj[0].LastName.substring(0, 3)+Integer.valueof((Math.random() * 10000)),
                    Email = contactObj[0].Email,
                    MobilePhone=contactObj[0].MobilePhone,
                    EmailEncodingKey = 'UTF-8',
                    FirstName = contactObj[0].FirstName,
                    LastName =contactObj[0].LastName,
                    CommunityNickname = contactObj[0].LastName+string.valueOf(math.random()).substring(0,6),
                    TimeZoneSidKey = 'Asia/Dubai', 
                    LocaleSidKey = 'en_US', 
                    LanguageLocaleKey = 'en_US',
                    UserPreferencesDisableAllFeedsEmail = true
                );
                insert portalUser;
                if(portalUser.Id != null && !retailTenantPermission.isEmpty()){
                    for(PermissionSet pm: retailTenantPermission){
                        addPermissionSet(portalUser.Id, pm.Id);
                    }
                }
                if( contactObj[0].Id != null ){
                    Contact con = new contact(Id=contactObj[0].Id);
                    con.Is_User_Created__c= true;
                    Update con;
                }
                
            }catch (DmlException e) {
                System.debug('Error creating portal user: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            } 
        }
        else if(!existingUser.isEmpty()){
            updateUserProfile(existingUser[0].Id);
            List<PermissionSetAssignment> ps = [
                SELECT PermissionSet.Name ,PermissionSet.Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :existingUser[0].Id 
            ];
            Map<Id, PermissionSetAssignment> permissionSetMap = new Map<Id,PermissionSetAssignment>();
            retailTenantPermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Retail_Contractor_Permission' ];
            for (PermissionSetAssignment p : ps) {
                permissionSetMap.put(p.PermissionSet.Id, p);
                
            }
            if( !retailTenantPermission.isEmpty()){
                for(PermissionSet pm: retailTenantPermission){
                    if(!permissionSetMap.ContainsKey(pm.Id)){
                        addPermissionSet(existingUser[0].Id, pm.Id);
                    }
                    
                }
            }
            //response.existingPermissions = new List<String>();
            
            
        }
    }
    @future()
    public static Void addPermissionSet(String portalUserId, String PermissionSetId){
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = portalUserId,
            PermissionSetId = PermissionSetId
        );
        insert psa;
    }
    @future()
    public static void updateUserProfile(string userId){
        String profileName = Label.DM_RequestorPortalProfile;
        List<Profile> portalProfile = [SELECT Id, name FROM Profile WHERE Name  =: profileName limit 1]; 
        User us = new User(id = userId);
        us.ProfileId = portalProfile[0].Id;
        update us;
    }
}