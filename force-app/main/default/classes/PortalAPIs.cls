public with sharing class PortalAPIs {
    @AuraEnabled
    public static User getProfileInfo(){
        String userId = UserInfo.getUserId();
        return [SELECT Contact.FirstName,Contact.LastName,Profile.Name,Account.Name,SmallPhotoUrl,FullPhotoUrl,Account.AgencyStatus__c, Contact.BlockSales__c from USER WHERE Id =:userId];
    }
}