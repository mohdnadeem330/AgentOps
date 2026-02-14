/**
* ActivityControllerTest
*
* Test class for AppointmentController
*/
@isTest
private class AppointmentControllerTest{
    
    //Creating test data
    @testSetup static void setupData() {
        
        
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'JO20220211');
        insert personAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(personAcc.Id);
        insert opp;
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        System.debug('orgAcc '+orgAcc);
       // insert orgAcc;
        
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        //SMS Mock
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        /* Create Lead From Account Record
        
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        
        System.runAs(salesManager) {
            Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
            leadRec.ExistingAccount__c = personAcc.Id;
            leadRec.IsCreateFromExistingAccount__c = true;
            leadRec.OwnerId = UserInfo.getUserId();
            //leadRec.Lead_Type__c = 'AM Sale';
            insert leadRec;
        } */
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        
        System.runAs(salesManager) {
            Account personAcc1 = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
            personAcc1.Email__c = 'Henry.Wong1@gmail.com';   
            personAcc1.MobileCountryCode__pc = '971' ;
            personAcc1.MobilePhone__pc = '52887687' ;
            insert personAcc1;
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
            
            User userDetail = Utilities.getLoggedInUserDetail();
            Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = 'Direct Call';
            leadRec2.EnquiryCategory__c = 'Aldar Employees';
            leadRec2.EnquiryTrigger__c = 'Provis';
            leadRec2.ExistingAccount__c = personAcc1.Id;
            insert leadRec2;
            
            TriggerHandler.processedIds = new Set<Id>();
            Lead newLead1 = new Lead();
            newLead1.Id = leadRec2.Id;
            newLead1.Status=Constants.QUALIFIED;
            
            Task taskForLead1 = TestObjectsFactory.getLeadActivity(newLead1.Id);
            taskForLead1.CustomerResponse__c = 'Customer Reached';
            update taskForLead1;
            //LeadTriggerHandler.updateExistingAccounts(new List<Lead>{leadRec2});
        }
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.AppointmentSystemID__c='123';
        insert projectRecord;
    }
    
    @isTest
static void testAppointment() {
    // Step 1: Prepare test data - perform all inserts and updates here BEFORE startTest
    Contact conRecord = [SELECT Id FROM Contact LIMIT 1];
    Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
    Lead leadRecord = [SELECT Id FROM Lead LIMIT 1];
    Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
    User tempURecord = AppointmentController.getUserData(UserInfo.getUserId());

    Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());

    Test.startTest();

    AppointmentController.getProjectLocations(tempURecord, projectRecord.Id);
    AppointmentController.getAvailableDates(tempURecord, projectRecord.Id, '123');
    AppointmentController.getAvailableTimeSlots(tempURecord, projectRecord.Id, '123', '123');
    AppointmentController.getBuyerData(leadRecord.Id);
    AppointmentController.getBuyerData(opportunityRecord.Id);
    AppointmentController.getBuyerData(conRecord.Id);

    // Prepare the map for booking appointment
    Map<String, String> requestInnerMap = new Map<String, String>{
        'agencyId' => 'aa',
        'leadType' => 'aa',
        'brokerFirstname' => 'aa',
        'brokerLastName' => 'aa',
        'brokerEmail' => 'aa',
        'email' => 'aa@aa.com',
        'brokerPhoneCountryCode' => 'aa',
        'brokerPhoneNumber' => 'aa',
        'residentCityId' => 'Dubai',
        'nationalityCode' => 'United Arab Emirates',
        'emiratesId' => 'aa',
        'passportNumber' => 'aa',
        'categoryName' => 'aa',
        'salesAgentName' => 'aa',
        'clientType' => 'aa',
        'bookingDate' => '07/28/2022',
        'leadId' => leadRecord.Id,
        'phoneCountryCode' => '971',
        'phone' => '9555222263',
        'nationality' => 'United Arab Emirates',
        'residencyStatus' => 'Resident',
        'slotId' => 'aa',
        'slotStartTime' => '3:40 PM',
        'slotEndTime' => '4:40 PM',
        'recordId' => leadRecord.Id,
        'LocationNameArabic' => 'test name'
    };

    AppointmentController.bookAppointment(tempURecord, projectRecord.Id, null, requestInnerMap);

    Test.stopTest();

}
    

    
    //Testing Appointment APIs for lead
    @isTest static void cancelAppointmentTest() {
        test.startTest();
        Contact conRecord = [select id from contact limit 1];
        Opportunity opportunityRecord = [select id from Opportunity limit 1];
        Lead leadRecord = [select id from Lead limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        Lead leadRec = [select id from lead limit 1];
        User tempURecord=AppointmentController.getUserData(userInfo.getUserId());
        Appointment__c app = new Appointment__c();
        // Added By Moh Sarfraj for BPE-113
        app.RecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();
        app.Appointment_Status__c=AppointmentController.BOOKED_STATUS;
        app.AppointmentId__c='123456';
        app.Date__c = System.Today().addDays(3);
        app.Lead__c = leadRec.Id;
        insert app;
        
        AppointmentController.getEventAllAppointments(app.Id);
        
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        map<string,string> requestInnerMap = new map<string,string>();
        AppointmentController.cancelBookedAppointment(leadRec.Id,requestInnerMap);
        test.stopTest();
    }
    //Testing Appointment APIs for lead
    @isTest static void cancelBookedAppointmentFromQuickActionTest() {
        test.startTest();
        Contact conRecord = [select id from contact limit 1];
        Opportunity opportunityRecord = [select id from Opportunity limit 1];
        Lead leadRecord = [select id from Lead limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        Lead leadRec = [select id from lead limit 1];
        User tempURecord=AppointmentController.getUserData(userInfo.getUserId());
        Appointment__c app = new Appointment__c();
        // Added By Moh Sarfraj for BPE-113
        app.RecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();
        app.Appointment_Status__c=AppointmentController.BOOKED_STATUS;
        app.AppointmentId__c='123456';
        app.Date__c = System.Today().addDays(3);
        app.Lead__c = leadRec.Id;
        insert app;

        AppointmentController.getEventAllAppointments(app.Id);
        
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        map<string,string> requestInnerMap = new map<string,string>();
        // Added By Moh Sarfraj for BPE-113
        AppointmentController.cancelBookedAppointmentFromQuickAction(app.Id);
        test.stopTest();
    }
    
    //Testing Appointment APIs for lead
    @isTest static void createUpdateAgencyTest() {
        test.startTest();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        orgAcc.ERPID__c = '12345';
        update orgAcc;
        
        List<Id> accIds = new List<Id>();
        accIds.add(orgAcc.Id);
        
        
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        AppointmentController.processNewBrokerAgency(accIds);
        AppointmentController.getCancellationReasonPicklist();
        //AppointmentController.captureExceptionLogger(null, 'processName', orgAcc.Id, 'methodName');
        test.stopTest();
    }
    
    @isTest static void rescheduleAppointmentTest() {
        Test.startTest();
        Contact conRecord = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Lead leadRecord = [select id from Lead limit 1];
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        User tempURecord = AppointmentController.getUserData(UserInfo.getUserId());
        
        Appointment__c app = new Appointment__c();
        app.Appointment_Status__c = AppointmentController.BOOKED_STATUS;
        app.AppointmentId__c ='123458';
        app.Date__c = System.Today().addDays(3);
        app.Lead__c = leadRec.Id;
        insert app;
        
        
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        
        Map<string,string> requestInnerMap = new Map<string,string>();
        requestInnerMap.put('agencyId','aa');
        requestInnerMap.put('leadType','aa');
        requestInnerMap.put('brokerFirstname','aa');
        requestInnerMap.put('brokerLastName','aa');
        requestInnerMap.put('brokerEmail','aa');
        requestInnerMap.put('email','aa@aa.com');
        requestInnerMap.put('brokerPhoneCountryCode','aa');
        requestInnerMap.put('brokerPhoneNumber','aa');
        requestInnerMap.put('residentCityId','Dubai');
        requestInnerMap.put('nationalityCode','United Arab Emirates');
        requestInnerMap.put('emiratesId','aa');
        requestInnerMap.put('passportNumber','aa');
        requestInnerMap.put('residentCityId','Dubai');
        requestInnerMap.put('categoryName','aa');
        requestInnerMap.put('salesAgentName','aa');
        requestInnerMap.put('clientType','aa');
        requestInnerMap.put('bookingDate','07/28/2022');
        requestInnerMap.put('leadId',leadRec.id);
        requestInnerMap.put('phoneCountryCode','aa');
        requestInnerMap.put('phone','aa');
        requestInnerMap.put('nationality','United Arab Emirates');
        requestInnerMap.put('residencyStatus','Resident');
        requestInnerMap.put('slotId','aa');
        requestInnerMap.put('recordId',leadRec.id);
        
        AppointmentController.bookAppointment(tempURecord, projectRecord.Id, app.Id, requestInnerMap);
        Test.stopTest();
    }
    
    

    // Added By Moh Sarfraj for BPE-113
    @isTest static void testAldarExpertsAppointment() {
        Contact conRecord = [select id from contact limit 1];
        Lead leadRec = [select id from lead limit 1];
        User tempURecord = AppointmentController.getUserData(userInfo.getUserId());

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        AppointmentController.getEventProjectDetails(System.Label.BPEAldarExpertProjectName.split(',')[0]);
        AppointmentController.getEventProjectLocations(tempURecord, '123');
        AppointmentController.getEventAvailableDates(tempURecord, '123', System.Label.BPEAldarExpertProjectName.split(',')[0]);
        AppointmentController.getEventAvailableTimeSlots(tempURecord, '123', '123', System.Label.BPEAldarExpertProjectName.split(',')[0]);
        
        map<string,string> requestInnerMap =new map<string,string>();
        requestInnerMap.put('agencyId','aa');
        requestInnerMap.put('leadType','aa');
        requestInnerMap.put('brokerFirstname','aa');
        requestInnerMap.put('brokerLastName','aa');
        requestInnerMap.put('brokerEmail','aa');
        requestInnerMap.put('email','aa@aa.com');
        requestInnerMap.put('brokerPhoneCountryCode','aa');
        requestInnerMap.put('brokerPhoneNumber','aa');
        requestInnerMap.put('residentCityId','Dubai');
        requestInnerMap.put('nationalityCode','United Arab Emirates');
        requestInnerMap.put('emiratesId','aa');
        requestInnerMap.put('passportNumber','aa');
        requestInnerMap.put('residentCityId','Dubai');
        requestInnerMap.put('categoryName','Events');
        requestInnerMap.put('salesAgentName','aa');
        requestInnerMap.put('clientType','aa');
        requestInnerMap.put('bookingDate','07/28/2022');
        requestInnerMap.put('leadId',leadRec.id);
        requestInnerMap.put('phoneCountryCode','971');
        requestInnerMap.put('phone','9555222263');
        requestInnerMap.put('nationality','United Arab Emirates');
        requestInnerMap.put('residencyStatus','Resident');
        requestInnerMap.put('slotId','aa');
        requestInnerMap.put('selectedLocationValue', 'loc');

        AppointmentController.bookEventAppointment(tempURecord, requestInnerMap, true);
        test.stopTest();
    }
    @isTest
    static void testCallCreateOrUpdateAgentExtraSlot() {
        Id orgRecordTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey('Organization')) {
            orgRecordTypeId = rtMap.get('Organization').getRecordTypeId();
        }
        
        Account orgAcc = new Account(
            Name = 'Test Org',
            AppointmentSystemID__c = 'AGENCY123'
        );
        if (orgRecordTypeId != null) {
            orgAcc.RecordTypeId = orgRecordTypeId;
        }
        insert orgAcc;
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = orgAcc.Id,
            AllowAdditionalAppointmentSlots__c = true,
            AdditionalAppointmentSlots__c = 3
        );
        insert con;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];
    User usr = new User(
        Username = 'testuser002' + Math.random().intValue() + '@test.com',
        Alias = 'tuser',
        Email = 'testuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        ContactId = con.Id,
        LastName = 'test'
    );
    insert usr;
        
        Test.setMock(HttpCalloutMock.class, new AppointmentMockResponse());
        
        Test.startTest();
        
        AppointmentController.processContactFuture(new List<Id>{con.Id});
        
        
        Test.stopTest();
        
        Contact updatedCon = [SELECT Id, AdditionalAppointmentSlots__c, AllowAdditionalAppointmentSlots__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(3, updatedCon.AdditionalAppointmentSlots__c); // Based on mock response
        System.assertEquals(true, updatedCon.AllowAdditionalAppointmentSlots__c);
    }
    


    @IsTest
    static void convertLead(){
        Lead leadRecord = [select id from Lead limit 1];
        Test.startTest();
        AppointmentController.convertLead(leadRecord.Id);
        Test.stopTest(); 
    }
    @isTest
static void testGetCountyCodePicklist() {
    List<Map<String, String>> result = AppointmentController.getCountyCodePicklist();
    
    System.assertNotEquals(null, result, 'The returned picklist should not be null');
    System.assert(result.size() > 0, 'The picklist should contain at least one entry');
    
    Map<String, String> firstEntry = result[0];
    System.assert(firstEntry.containsKey('label'), 'Entry should contain label key');
    System.assert(firstEntry.containsKey('value'), 'Entry should contain value key');
}
    @istest
    static void testHasFutureAppointment() {
    
    Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
    
    Appointment__c futureApp = new Appointment__c();
    futureApp.Lead__c = leadRec.Id;
    futureApp.Date__c = System.today().addDays(5);  // future date
    futureApp.Appointment_Status__c = AppointmentController.BOOKED_STATUS;  // Use the constant
    futureApp.Appointment_Slot_Time__c = '10:00 AM - 11:00 AM';
    futureApp.Location__c = 'Test Location';
    futureApp.Project__c = null;  // or some test project Id
    futureApp.Appointment_Location__c = 'Test Location Name';
    futureApp.Slot__c = 'Slot1';
    futureApp.AppointmentId__c = 'APP123456';
    insert futureApp;

    // Call the method under test
    List<Appointment__c> result = AppointmentController.hasFutureAppoitment(leadRec.Id);

    // Assertions
    System.assertNotEquals(null, result, 'The result should not be null');
    System.assert(result.size() > 0, 'There should be at least one future appointment');
    System.assertEquals(futureApp.Id, result[0].Id, 'The appointment returned should match the inserted one');
}
    @isTest
static void testGetNationalitiesPicklist() {
    List<Map<String, String>> nationalities = AppointmentController.getNationalitiesPicklist();
    System.assertNotEquals(null, nationalities, 'The nationalities picklist result should not be null');
    System.assert(nationalities.size() > 0, 'The nationalities picklist should have values');
}

@isTest
static void testGetCustomerPresencePicklist() {
    List<Map<String, String>> customerPresence = AppointmentController.getCustomerPresencePicklist();
    System.assertNotEquals(null, customerPresence, 'The customer presence picklist result should not be null');
    System.assert(customerPresence.size() > 0, 'The customer presence picklist should have values');
}
 private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String mockJson = '{' +
                '"results": [' +
                    '{"ProjectId":"123","ProjectName":"Test Project AUH","IsAUHEnabled":true,"IsDXBEnabled":false,"IsINTEnabled":false,"IsALLEnabled":false},' +
                    '{"ProjectId":"456","ProjectName":"Test Project INT","IsAUHEnabled":false,"IsDXBEnabled":false,"IsINTEnabled":true,"IsALLEnabled":false},' +
                    '{"ProjectId":"789","ProjectName":"Test Project ALL","IsAUHEnabled":false,"IsDXBEnabled":false,"IsINTEnabled":false,"IsALLEnabled":true}' +
                ']' +
            '}';
            res.setBody(mockJson);
            return res;
        }
    }

   @isTest
static void testGetAllProjects() {
    // Set mock HTTP callout
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    String brokerAgentRTDevName = 'BrokerAgent'; 
    Id brokerAgentRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(brokerAgentRTDevName).getRecordTypeId();

    Account acct = new Account(
        Name = 'Test Account',
        BillingCity = 'Abu Dhabi',
        BillingState = 'Abu Dhabi',
        BillingCountry = 'United Arab Emirates'
    );
    insert acct;

    Contact cont = new Contact(
        FirstName = 'Test',
        LastName = 'User',
        AccountId = acct.Id,
        RecordTypeId = brokerAgentRTId,
        BrokerType__c = 'Agent' 
    );
    insert cont;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];
    User usr = new User(
        Username = 'testuser001' + Math.random().intValue() + '@test.com',
        Alias = 'tuser',
        Email = 'testuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        ContactId = cont.Id,
        LastName = 'test'
    );
    insert usr;

    List<Project__c> projects = new List<Project__c>{
        new Project__c(Name = 'Test Project AUH', AppointmentSystemID__c = '123', BusinessUnitId__c = '7164', ProjectCode__c = 'abc'),
        new Project__c(Name = 'Test Project INT', AppointmentSystemID__c = '456', BusinessUnitId__c = '7162', ProjectCode__c = 'abcd'),
        new Project__c(Name = 'Test Project ALL', AppointmentSystemID__c = '789', BusinessUnitId__c = '7163', ProjectCode__c = 'abec')
    };
    insert projects;

    System.runAs(usr) {
        Test.startTest();
        List<Map<String, String>> result = AppointmentController.getAllProjects();
        Test.stopTest();


        
        Set<String> expectedLabels = new Set<String>{ 'Test Project AUH', 'Test Project ALL' };

        for (Map<String, String> mapItem : result) {
            System.assert(expectedLabels.contains(mapItem.get('label')), 'Unexpected project label: ' + mapItem.get('label'));
            System.assertNotEquals(null, mapItem.get('value'), 'Project Id (value) should not be null');
        }
    }
}

    @isTest 
    static void testGetResidencePicklist() {
        Test.startTest();
        List<Map<String, String>> residencePicklist = AppointmentController.getResidencePicklist();
        Test.stopTest();

        System.assertNotEquals(0, residencePicklist.size(), 'Residence picklist should not be empty');
        
        for (Map<String, String> entry : residencePicklist) {
            System.assert(entry.containsKey('label'), 'Entry should have label key');
            System.assert(entry.containsKey('value'), 'Entry should have value key');
            System.assertEquals(entry.get('label'), entry.get('value'), 'Label and value should be same for Residence picklist');
        }
    }

    @isTest 
    static void testGetEmiratesPicklist() {
        Test.startTest();
        List<Map<String, String>> emiratesPicklist = AppointmentController.getEmiratesPicklist();
        Test.stopTest();

        System.assertNotEquals(0, emiratesPicklist.size(), 'Emirates picklist should not be empty');
       
        for (Map<String, String> entry : emiratesPicklist) {
            System.assert(entry.containsKey('label'), 'Entry should have label key');
            System.assert(entry.containsKey('value'), 'Entry should have value key');
            System.assertNotEquals('', entry.get('label'), 'Label should not be empty');
            System.assertNotEquals('', entry.get('value'), 'Value should not be empty');
        }
    }
    @isTest
    static void testGetAllProjects2() {
        // Set mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        
        String brokerAgentRTDevName = 'BrokerAgent'; 
        Id brokerAgentRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(brokerAgentRTDevName).getRecordTypeId();

        
        Account acct = new Account(
            Name = 'Test Account',
            BillingCity = 'Dubai',
            BillingState = 'Dubai', 
            BillingCountry = 'United Arab Emirates'
        );
        insert acct;

       
        Contact cont = new Contact(
            FirstName = 'Test',
            LastName = 'User', 
            AccountId = acct.Id,
            RecordTypeId = brokerAgentRTId,
            BrokerType__c = 'Agent' 
        );
        insert cont;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];
        User usr = new User(
            Username = 'testuser003'+Math.random().intValue()+'@test.com',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = cont.Id,
            lastname='test'
        );
        insert usr;
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'Test Project AUH', AppointmentSystemID__c = '123',BusinessUnitId__c='7164', ProjectCode__c='abc'),
            new Project__c(Name = 'Test Project INT', AppointmentSystemID__c = '456',BusinessUnitId__c='7162', ProjectCode__c='abcd'),
            new Project__c(Name = 'Test Project ALL', AppointmentSystemID__c = '789',BusinessUnitId__c='7163', ProjectCode__c='abec')
        };
        insert projects;

        System.runAs(usr) {
            Test.startTest();
            List<Map<String, String>> result = AppointmentController.getAllProjects();
            Test.stopTest();

            Set<String> expectedLabels = new Set<String>{ 'Test Project AUH', 'Test Project ALL' };
            for (Map<String, String> mapItem : result) {
                System.assert(expectedLabels.contains(mapItem.get('label')), 'Unexpected project label: ' + mapItem.get('label'));
                System.assertNotEquals(null, mapItem.get('value'), 'Value should not be null');
            }
        }
    }
    
    
}