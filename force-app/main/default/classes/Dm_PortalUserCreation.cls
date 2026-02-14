/**
Class       : Dm_PortalUserCreation
Author      : Smaartt
Description : This class is accessed from LWC to create portal users
TestClass   : Dm_PortalUserCreationTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              24/07/24           Initial Version 
****************************************************************************************************************/
public without sharing class Dm_PortalUserCreation {
    @AuraEnabled
    public static void createPortalUser( Id contactId, boolean duplicate) {
        
        string dmContactRecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_ContactRecordType).getRecordTypeId();
        Contact contactObj = [SELECT Id, Email,Firstname,AccountId, LastName, MobilePhone,RecordTypeId FROM Contact WHERE Id = :contactId and RecordTypeId =: dmContactRecordTypeId LIMIT 1];
        system.debug('contactObj--'+contactObj);
        
        if (contactObj != null) {
            contactObj.ownerId = UserInfo.getUserId();
            Update contactObj;
            Account acc = new Account(Id=contactObj.AccountId);
            acc.ownerId = UserInfo.getUserId();
            Update acc;
            String profileName = Label.DM_RequestorPortalProfile;
            Profile portalProfile = [SELECT Id, name FROM Profile WHERE Name  =: profileName];               
            Organization org = Utilities.getOrganizationDetails();
            Boolean isSandbox  = org.IsSandbox;
            List<String> emailSplit = contactObj.Email.split('@');
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
                    ContactId = contactObj.Id,
                    ProfileId = portalProfile.Id,
                    Alias = contactObj.LastName.substring(0, 3)+Integer.valueof((Math.random() * 10000)),
                    Email = contactObj.Email,
                    MobilePhone=contactObj.MobilePhone,
                    EmailEncodingKey = 'UTF-8',
                    FirstName = contactObj.FirstName,
                    LastName =contactObj.LastName,
                    CommunityNickname = contactObj.LastName+string.valueOf(math.random()).substring(0,6),
                    TimeZoneSidKey = 'Asia/Dubai', 
                    LocaleSidKey = 'en_US', 
                    LanguageLocaleKey = 'en_US',
                    UserPreferencesDisableAllFeedsEmail = true
                );
                insert portalUser;
                
                Contact con = new contact(Id=contactObj.Id);
                con.Is_User_Created__c= true;
                Update con;
                    
            }catch (DmlException e) {
                System.debug('Error creating portal user: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            } 
        }
    }
}