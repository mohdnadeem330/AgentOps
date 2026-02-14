public class ECSS_OccupantDetails {

    @AuraEnabled public String firstName {get;set;}
    @AuraEnabled public String lastName{get;set;}
    @AuraEnabled public String email{get;set;}
    @AuraEnabled public String relationship{get;set;}
    @AuraEnabled public Date dateOfBirth{get;set;}
    @AuraEnabled public String nationalId{get;set;}
    @AuraEnabled public String passportNumber{get;set;}
    @AuraEnabled public String mobileCountryCode{get;set;}
    @AuraEnabled public String mobileNumber{get;set;}
    @AuraEnabled public Id relatedAccountId{get;set;}
    @AuraEnabled public Id assetId {get;set;}
    @AuraEnabled public Id quoteId {get;set;}
    @AuraEnabled public Id opportunityId {get;set;}
    
}