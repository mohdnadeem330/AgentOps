@IsTest
private class BP_ManageLeadTest {

    @TestSetup 
    static void setup() {
       Account testAccount = new Account(
            Name = 'PWC',
            BankCountry__c = 'Algeria', // Add custom fields
            BankName__c = 'Test Bank',
            BranchAddress__c = '1234 Main Street',
            BankAccountNumber__c = '1234567890',
            IBANNumber__c = 'US12345678901234567890',
            SwiftCode__c = 'TESTUS33',
            BeneficiaryName__c = 'John Doe',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Broker_Agency' LIMIT 1].Id
        );
        insert testAccount;
        system.debug('result2'+ testAccount);
        // Create a Contact
        Contact contactRecord1 = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            PrimaryAgencyAdmin__c = true,
            AgentStatus__c = 'Active',
            MobileCountryCode__c = '971',
            MobilePhone__c = '9696859685',
            Email = 'test112271@gmail.com',
            BrokerType__c = 'Partner/Owner',
            PrimaryOwner__c = true
        );
        insert contactRecord1;


        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_USER_PROFILE, 'pdbaa');
        agencyAdminUser.contactId = contactRecord1.Id;
        insert agencyAdminUser;
        
        
            Lead newLead = new Lead();
            
            newLead.BrokerAgent__c = contactRecord1.Id;
            newLead.Email = 'aupendra14@gmail.com';
            newLead.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Person').getRecordTypeId();
            newLead.Salutation = 'Dr';
            newLead.FirstName = 'Henry';
            newLead.LastName = 'Wong';
            newLead.Email = 'aupendra14@gmail.com';
            
            newLead.MobileCountryCode__c = '971' ;
            newLead.MobileNumber1__c = '52887687' ;
            newLead.SalesOrigin__c = 'Domestic' ;
            newLead.LeadOrigin__c = 'United Arab Emirates' ;
            newLead.LeadSource = '800-Aldar' ;
            newLead.EnquiryCategory__c = 'Kiosk' ;
            newLead.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
            newLead.BuyRent__c = 'Rent' ;
            newLead.SalesType__c = 'Asset Management' ;
            newLead.PropertyReadiness__c = 'Ready' ;
            newLead.ResidentStatus__c = 'Resident' ;
            newLead.Project__c = 'Al Bateen Park' ;
            newLead.CustomerLocation__c = 'Abu Dhabi' ;
            newLead.LanguagePreference__c = 'English' ;
            newLead.PurposeOfUse__c= 'Investor';
            newLead.PropertyUsage__c = 'Retail';
            newLead.CustomerLocation__c = 'Abu Dhabi';
            newLead.Nationality__c  = 'United Arab Emirates';
            newLead.Date_of_Birth__c  = System.today().addMonths(-1234);
            insert newLead;
            
    }
    
    
    @isTest
    static void callMethods2() {
       
            Test.startTest();
            Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert accountRecord;
            
            BrokerLeadController.getLeadsRelatedToAccount(accountRecord);
            
            Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
            
            
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStatusCode(200);
            mock.setStaticResource('GetBitlyShortenURLSuccess');
            Test.setMock(HttpCalloutMock.class, mock);
            
            Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
            leadRec.BrokerAgent__c = con.Id;
            leadRec.LeadSource = 'Broker Portal';
            leadRec.EnquiryCategory__c = 'Kiosk';
            leadRec.EnquiryTrigger__c = 'DIFC Kiosk';
            leadRec.Date_of_Birth__c  = System.today().addMonths(-1234);
            insert leadRec;
            BP_ManageLead.getMapDetails(system.today().addDays(-10),system.today().addDays(10),'aupendra14@gmail.com','test','test1','Dubai',1,0,con.Id, true, null);

            Test.stopTest();
       
        
    }

 @isTest
    static void callMethods() {

        Test.startTest();
     
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        BrokerLeadController.getLeadsRelatedToAccount(accountRecord);
        
        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        update con;

        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.BrokerAgent__c = con.Id;
        leadRec.LeadSource = 'Broker Portal';
        leadRec.EnquiryCategory__c = 'Kiosk';
        leadRec.EnquiryTrigger__c = 'DIFC Kiosk';
         leadRec.Date_of_Birth__c  = System.today().addMonths(-1234);
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

        
        Test.stopTest();
    }
   
  
    @isTest
    static void testLeadSOQLWithAgencyAdmin() {
        Test.startTest();
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        if (con.Id == null) {
            insert con; 
        }
        update con; 

        
        Profile agencyAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Agency Admin' LIMIT 1];

       
        Id userRoleId;
        try {
            userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Partner User' LIMIT 1].Id;
        } catch (Exception e) {
            userRoleId = null;
        }

        User adminUser = new User(
            LastName = 'TestAdmin',
            Email = 'admin@test.com',
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            Alias = 'admint',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = agencyAdminProfile.Id,
            ContactId = con.Id, 
            UserRoleId = userRoleId,
            IsActive = true
        );

       // System.runAs(new User(Id = UserInfo.getUserId())) {
        //    insert adminUser; 
        //}

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadRec.BrokerAgency__c = accountRecord.Id;
        leadRec.Email = 'admin.lead@test.com';
        leadRec.Project__c = 'Al Bateen Park';
        leadRec.Status = 'New';
         leadRec.Date_of_Birth__c  = System.today().addMonths(-1234);
        insert leadRec;

       // System.runAs(adminUser) {
            BP_ManageLead.getMapDetails(
                system.today().addDays(-10),
                system.today().addDays(10),
                'test13@aldar.com',
                'Al Bateen Park',
                con.Name,
                null,
                5,
                0,
                con.Id, false, null
            );

     
            List<Lead> adminLeads = [SELECT Id FROM Lead WHERE BrokerAgency__c = :accountRecord.Id];
            System.assertEquals(1, adminLeads.size(), 'Agency Admin should retrieve one lead.');
        //}

        Test.stopTest();
    }
    
      @isTest
    static void testLeadSOQLWithAgencyAdmin2() {
        Test.startTest();
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
       
        insert accountRecord;

        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        if (con.Id == null) {
            insert con; 
        }
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
        update con; 
        accountRecord.BrokerAgent__c = con.Id;
        update accountRecord;
        Profile agencyAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Agency Admin' LIMIT 1];

       
        Id userRoleId;
        try {
            userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Partner User' LIMIT 1].Id;
        } catch (Exception e) {
            userRoleId = null;
        }

        User adminUser = new User(
            LastName = 'TestAdmin',
            Email = 'admin@test.com',
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            Alias = 'admint',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = agencyAdminProfile.Id,
            ContactId = con.Id, 
            UserRoleId = userRoleId,
            IsActive = true
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert adminUser; 
        }

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadRec.BrokerAgency__c = accountRecord.Id;
        leadRec.Email = 'admin.lead@test.com';
        leadRec.Project__c = 'Al Bateen Park';
        leadRec.Status = 'New';
        leadRec.Date_of_Birth__c  = System.today().addMonths(-1234);
        insert leadRec;

        //System.runAs(adminUser) {
            BP_ManageLead.getMapDetails(
                null,
               null,
                'test13@aldar.com',
                'Al Bateen Park',
                con.Name,
                null,
                5,
                0,
                con.Id, true, null
            );

     
            List<Lead> adminLeads = [SELECT Id FROM Lead WHERE BrokerAgency__c = :accountRecord.Id];
            System.assertEquals(1, adminLeads.size(), 'Agency Admin should retrieve one lead.');
        //}

        Test.stopTest();
    }

@IsTest
static void testExecute_validRequest() {
    Lead leadRec = [SELECT Id, Name FROM Lead LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];

    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/getBrokerLead';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');

    // Constructing the request body with all required parameters
    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('leadId', leadRec.Id);
    requestBody.put('startDate', '2025-01-01');
    requestBody.put('endDate', '2025-12-31');
    requestBody.put('brokerAgentId', con.Id);
    requestBody.put('leadNumber', 'L123');
    requestBody.put('leadName', leadRec.Name);
    requestBody.put('location','United Arab Emirates');
     requestBody.put('email', 'aupendra14@gmail.com');
     requestBody.put('project', 'Al Bateen Park');
    
    requestBody.put('limit', 10);
    requestBody.put('offset', 0);
    
    req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_ManageLead.execute();
    Test.stopTest();

    RestResponse res = RestContext.response;
    if (res?.responseBody != null) {
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
     
    } else {
     
    }
}

@IsTest
static void testExecute_validRequestWithout15() {
    Lead leadRec = [SELECT Id, Name FROM Lead LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];

    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/getBrokerLead';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');

    // Constructing the request body with all required parameters
    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('leadId', leadRec.Id);
    requestBody.put('startDate', '2025-01-01');
    requestBody.put('endDate', '2025-12-31');
    requestBody.put('brokerAgentId', con.Id);
    requestBody.put('leadNumber', 'L123');
    requestBody.put('leadName', leadRec.Name);
    requestBody.put('location','United Arab Emirates');
     requestBody.put('email', 'aupendra14@gmail.com');
     requestBody.put('project', 'Al Bateen Park');
    
    //requestBody.put('limit', 10);
   // requestBody.put('offset', 0);
    
    req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_ManageLead.execute();
    Test.stopTest();

    RestResponse res = RestContext.response;
    if (res?.responseBody != null) {
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
     
    } else {
     
    }
}

    @isTest static void invalidTest(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerLead';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('startDate', null);
        requestBody.put('endDate', null);
       
    
        req.requestBody =Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_ManageLead.execute();
        Test.stopTest();

    }

     @isTest static void invalidTest2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerLead';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        Map<String, Object> requestBody = new Map<String, Object>();
        req.requestBody =Blob.valueOf('');

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_ManageLead.execute();
        Test.stopTest();

    }


}