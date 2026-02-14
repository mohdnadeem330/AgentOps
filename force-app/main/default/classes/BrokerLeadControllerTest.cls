@isTest
private class BrokerLeadControllerTest {
    
    @isTest() 
    static void callMethods1() {
        Test.startTest();
        BrokerLeadController.getCountryCodeValues();
        BrokerLeadController.getPropertyPicklistValues();
        BrokerLeadController.getNoOfBedroomPicklistValues();
        BrokerLeadController.getLeadOriginPicklistValues();
        BrokerLeadController.getLeadOriginPicklistValues();
        BrokerLeadController.getEmiratesValues();
        BrokerLeadController.validateBrokersEmailMobileForLeadCreation('sarfraj@gmail.com', 'email');
        Test.stopTest();

    }

    @isTest
    static void callMethods2() {
        Test.startTest();

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        BrokerLeadController.getLeadsRelatedToAccount(accountRecord);
        
        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);

        // User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
        // agencyAdmin.ContactId = con.Id;
        // agencyAdmin.Email = 'ali.athamneh@pwc.com';
        // insert agencyAdmin;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.BrokerAgent__c = con.Id;
        leadRec.LeadSource = 'Broker Portal';
        leadRec.EnquiryCategory__c = 'Kiosk';
        leadRec.EnquiryTrigger__c = 'DIFC Kiosk';
        insert leadRec;
        BrokerLeadController.getMapDetails(system.today().addDays(-10),system.today().addDays(10));
        Test.stopTest();

    }

    @isTest
    static void callMethods() {

        Test.startTest();
        //BrokerLeadController.getLeadQuery('SELECT FirstName, BrokerAgent__r.Name, LastName, Email, MobileNumber1__c, Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, createdDate, City, PassportNumber__c, PassportExpiryDate__c, Nationality__c, Country, Project__c, UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c,  BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, LastModifiedDate FROM Lead Where IsConverted = false Order By LastModifiedDate desc limit 10');

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        BrokerLeadController.getLeadsRelatedToAccount(accountRecord);
        
        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        update con;

        // User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
        // agencyAdmin.ContactId = con.Id;
        // agencyAdmin.Email = 'ali.athamneh@pwc.com';
        // insert agencyAdmin;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.BrokerAgent__c = con.Id;
        leadRec.LeadSource = 'Broker Portal';
        leadRec.EnquiryCategory__c = 'Kiosk';
        leadRec.EnquiryTrigger__c = 'DIFC Kiosk';
        insert leadRec;
        
        BrokerLeadController.getLeadsRelatedToContact(con.Id);

        Map<String, Object> leadInfoObject = new Map<String, Object>();
        leadInfoObject.put('mobileNumber','962787120342');
        leadInfoObject.put('emailAddress','Test.test@test.com');
        leadInfoObject.put('title','Mr');
        leadInfoObject.put('countryCode',leadRec.MobileCountryCode__c);
        leadInfoObject.put('firstName','test');
        leadInfoObject.put('lastName','test');
        leadInfoObject.put('residentStatus',leadRec.ResidentStatus__c);
        leadInfoObject.put('nationality',leadRec.Nationality__c);
        leadInfoObject.put('city','Dubai');
        leadInfoObject.put('salesType',leadRec.SalesType__c);
        leadInfoObject.put('propertyUsage',leadRec.PropertyUsage__c);
        leadInfoObject.put('buyRent',leadRec.BuyRent__c);
        leadInfoObject.put('property',leadRec.Project__c);
        leadInfoObject.put('unitType',leadRec.UnitType__c);
        leadInfoObject.put('numberOfBeds',leadRec.NumberOfBedrooms__c);
        leadInfoObject.put('events',leadRec.Offer1__c);
        leadInfoObject.put('purposeOfUse',leadRec.PurposeOfUse__c);
        leadInfoObject.put('bulk',leadRec.Bulk__c);
        leadInfoObject.put('propertyReadiness',leadRec.PropertyReadiness__c);
        leadInfoObject.put('financing',leadRec.Financing__c);
        leadInfoObject.put('customerBudget',leadRec.CustomerBudget__c);
        leadInfoObject.put('emiratesID',leadRec.NationalId__c);
        leadInfoObject.put('passportNumber',leadRec.PassportNumber__c);
        leadInfoObject.put('residanceCountry',leadRec.CountryOfResidence__c);
        leadInfoObject.put('mortgage',leadRec.Mortgage__c);
        leadInfoObject.put('enquiryCategory','Kiosk');
        leadInfoObject.put('enquiryTrigger','DIFC Kiosk');
        leadInfoObject.put('realMobileNumber','95659842');

        BrokerLeadController.createLead(leadInfoObject);
        BrokerLeadController.createLead(leadInfoObject);

        leadInfoObject.put('leadId',leadRec.Id);
        leadInfoObject.put('emailAddress','*********');
        leadInfoObject.put('mobileNumber','*********');

        BrokerLeadController.createLead(leadInfoObject);
        BrokerLeadController.getLeadById(leadRec.Id);
        BrokerLeadController.getsObjectType(leadRec.Id);
        BrokerLeadController.getsObjectType(con.Id);
        BrokerLeadController.getsobjectName(leadRec.Id);
        
        BrokerLeadController.maskString('testText', 0, 5, '*');
        
        Test.stopTest();
    }
}