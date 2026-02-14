@isTest
private class YardiCreateLeadTest {

    @isTest static  void validationCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetYardiCreateLeadSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec1 = TestObjectsFactory.getLeadToYardiRecord(1,'Person');
        leadRec1.OwnerId = UserInfo.getUserId();

        insert(leadRec1);

        Lead leadRec = [SELECT Id, Name, CreatedDate, Salutation, FirstName, MiddleName, LastName, Email, MobileCountryCode__c
        , MobileNumber1__c, SalesOrigin__c, LeadOrigin__c, LeadSource, EnquiryCategory__c, EnquiryTrigger__c, Financing__c,
        BuyRent__c, SalesType__c, PropertyReadiness__c, ResidentStatus__c, Project__c, PropertyUsage__c, CustomerLocation__c
        , LanguagePreference__c, Status, Phone, PurposeOfUse__c, LeadNumber__c, Country, MobilePhone, Company, CustomerBudget__c,
        Mortgage__c, UnitType__c, NumberOfBedrooms__c, AreaSqmt__c, OwnerId 
        FROM Lead WHERE Id =: leadRec1.Id LIMIT 1];

        Test.startTest();
        YardiCreateLead.LeadImport(new List<Lead>{leadRec});
        leadRec.CustomerBudget__c = '25M-AED 50M';
        YardiCreateLead.LeadImport(new List<Lead>{leadRec});
        Test.stopTest();
        
        // Fail Mock
        mock.setStaticResource('GetYardiCreateLeadFail');
        Test.setMock(HttpCalloutMock.class, mock);

        YardiCreateLead.LeadImport(new List<Lead>{leadRec});

    }
}