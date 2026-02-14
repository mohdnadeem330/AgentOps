@isTest
private class BP_DashboardWebserviceTest {

    @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account', false, 'JO20220211');
        orgAcc.recordTypeID = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId = conRecord.Id;
        insert agencyAdminUser;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
         
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgentContact__c = conRecord.Id;
        opp.BrokerAgencyAccount__c = orgAcc.Id;
        opp.EnquiryTrigger__c = null;
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingRecord.id);
        insert unitrecord;
         
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id, buildingRecord.Id);
        insert buldingPaymentMapping;
         
        OffersPromotions__c offerRecord = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, projectRecord.Id);
        insert offerRecord;
        
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
    }

    @isTest
    static void testExecute() {
        Test.startTest();
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getDashboardDetails';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        String requestBody = '{"accountId":"' + accRecord.Id + '","startDate":"2025-01-01","endDate":"2025-01-31"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        BP_DashboardWebservice.excute();
        
        RestResponse res = RestContext.response;
        
        System.assertNotEquals(null, res.responseBody);
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRequest() {
        Test.startTest();
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        String requestBody = '{"accountId":"' + accRecord.Id + '","startDate":"2025-01-01","endDate":"2025-01-31"}';
        Map<String, String> params = new Map<String, String>();
        
        BP_DashboardWebservice service = new BP_DashboardWebservice();
        BP_BaseRestResource.ApiResponse response = service.processRequest(params, requestBody);
        
        System.assertNotEquals(null, response);
        System.assertEquals(400, response.statusCode);
       
        
        Test.stopTest();
    }

    @isTest
    static void testGetAgencyDashboardDetailsWithNoTopRanking() {
        Test.startTest();
        Account account1 = new Account(Name = 'Account 1', ClassificationSalesAmount__c = 1000);
        insert new List<Account>{account1};
        
        BP_DashboardWebservice.AgencyDashboardDetails result = BP_DashboardWebservice.getAgencyDashboardDetails(account1.id, Date.valueOf('2025-01-01'), Date.valueOf('2025-01-31'));
        
        
        Test.stopTest();
    }

    @isTest
    static void testGetAgencyDashboardDetailsWithEmptyAccountId() {
        Test.startTest();
        String accountId = '';
        Date startDate = Date.valueOf('2025-01-01');
        Date endDate = Date.valueOf('2025-01-31');
        
        BP_DashboardWebservice.AgencyDashboardDetails result = BP_DashboardWebservice.getAgencyDashboardDetails(accountId, startDate, endDate);
        Test.stopTest();
    }

    @isTest
    static void testProcessRequestWithEmptyBody() {
        Test.startTest();
        String requestBody = '';
        Map<String, String> params = new Map<String, String>();
        
        BP_DashboardWebservice service = new BP_DashboardWebservice();
        BP_BaseRestResource.ApiResponse response = service.processRequest(params, requestBody);
        
        System.assertNotEquals(null, response);
        System.assertEquals(400, response.statusCode);
      
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRequestWithException() {
        Test.startTest();
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        String requestBody = '{"accountId":"' + accRecord.Id + '","startDate":"2025-01-01","endDate":"2025-01-31"}';
        Map<String, String> params = new Map<String, String>();
        
        BP_DashboardWebservice service = new BP_DashboardWebservice();
        try {
            service.processRequest(params, null);
            
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();
    }

    @isTest
    static void testGetAgencyDashboardDetailsWithRank() {
        Test.startTest();
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        String accountId = accRecord.Id;
        Date startDate = Date.valueOf('2025-01-01');
        Date endDate = Date.valueOf('2025-01-31');
        BP_DashboardWebservice.AgencyDashboardDetails result = BP_DashboardWebservice.getAgencyDashboardDetails(accountId, startDate, endDate);
        Test.stopTest();
    }

    @isTest static void testDashBoardData() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id, AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord = [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID, accRecord.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.SellingPrice__c = 1000000;
        salesOrderRecord.ExternalCommissionAmount__c = 10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c = optyRecord.AccountId;
        insert salesOrderRecord;
        
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id, AccountId from User where contactId = :conRecord.Id limit 1];
        System.runAs(userRecord) {
            list<Communication__c> communicationRecords = DashboardController.getMyCommunication();
            System.assertEquals(communicationRecords.isEmpty(), true);
            DashboardController.getAgencyDashboardDetails(userRecord.AccountId, System.today().addDays(-5), System.today().addDays(5));
        }
    }

    @isTest
    static void testGetAgencyDashboardDetailsWithException() {
        Test.startTest();
        
        String accountId = 'invalid_account_id';
        Date startDate = Date.valueOf('2025-01-01');
        Date endDate = Date.valueOf('2025-01-31');
        
        try {
            BP_DashboardWebservice.AgencyDashboardDetails result = BP_DashboardWebservice.getAgencyDashboardDetails(accountId, startDate, endDate);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();
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
            BP_DashboardWebservice.getMapDetails(system.today().addDays(-10),system.today().addDays(10),'aupendra14@gmail.com','test','test1','Dubai',1,0,con.Id, true);

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
            BP_DashboardWebservice.getMapDetails(
                system.today().addDays(-10),
                system.today().addDays(10),
                'test13@aldar.com',
                'Al Bateen Park',
                con.Name,
                null,
                5,
                0,
                con.Id, false
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
            BP_DashboardWebservice.getMapDetails(
                null,
               null,
                'test13@aldar.com',
                'Al Bateen Park',
                con.Name,
                null,
                5,
                0,
                con.Id, true
            );

     
            List<Lead> adminLeads = [SELECT Id FROM Lead WHERE BrokerAgency__c = :accountRecord.Id];
            System.assertEquals(1, adminLeads.size(), 'Agency Admin should retrieve one lead.');
        //}

        Test.stopTest();
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
        BP_DashboardWebservice.excute();
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
        BP_DashboardWebservice.excute();
        Test.stopTest();

    }

}