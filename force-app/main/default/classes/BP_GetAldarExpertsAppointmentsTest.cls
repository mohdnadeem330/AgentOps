@isTest
private class BP_GetAldarExpertsAppointmentsTest {

    @testSetup
    static void setupTestData() {
       // Step 1: Create an Account
        Account acct = new Account(Name = 'Test Account 1');
        insert acct;

        // Step 2: Create a Contact associated with the Account
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = acct.Id
        );
        insert contact;
        
        // Step 2: Create a Contact associated with the Account
        Contact contact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = acct.Id
        );
        insert contact1;

        // Step 3: Get a valid Profile for Customer/Partner Community User
        // NOTE: Replace the name based on your org (you can query Profile names in your org)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];

        // Step 4: Create a User and associate it with the Contact
        User portalUser = new User(
            Username = 'testusermohd123@example.com.test', // Must be unique
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = contact.Id
        );
        
        // Step 4: Create a User and associate it with the Contact
        User portalUser1 = new User(
            Username = 'testusermohd1234@example.com.test', // Must be unique
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = contact1.Id
        );

        // Set a Community User Role if required (mainly for Partner users)
        // portalUser.UserRoleId = ... (optional)

        // Required fields specific to your org settings
        portalUser.LastName = 'User';
        portalUser.CommunityNickname = 'testnick';
        
        portalUser1.LastName = 'User1';
        portalUser1.CommunityNickname = 'testnick1232342';
        
        insert portalUser;
        insert portalUser1;
        
        String aldarExpertRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();

        // Create appointments related to contact
        List<Appointment__c> appointments = new List<Appointment__c>{
            new Appointment__c( Contact__c = contact.Id, RecordTypeId = aldarExpertRecordTypeId ),
            new Appointment__c( Contact__c = contact.Id, RecordTypeId = aldarExpertRecordTypeId)
        };
        insert appointments;
    }

    @isTest
    static void testExecute_WithAppointments() {
        // Run as test user
        User testUser = [SELECT Id FROM User WHERE Username = 'testusermohd123@example.com.test'];
        System.runAs(testUser) {
            Test.startTest();

            // Simulate REST request context
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.httpMethod = 'GET';
            req.requestURI = '/services/apexrest/getAldarExpertsAppointments';
            RestContext.request = req;
            RestContext.response = res;

            BP_GetAldarExpertsAppointments.execute();

            Test.stopTest();
        }
    }

    

    @isTest
    static void testProcessRequest_NoAppointments() {
         // Step 1: Create an Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Step 2: Create a Contact associated with the Account
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = acct.Id
        );
        insert contact;

        // Step 3: Get a valid Profile for Customer/Partner Community User
        // NOTE: Replace the name based on your org (you can query Profile names in your org)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];

        // Step 4: Create a User and associate it with the Contact
        User portalUser = new User(
            Username = 'testusermogw11@example.com.test', // Must be unique
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = contact.Id
        );

        // Set a Community User Role if required (mainly for Partner users)
        // portalUser.UserRoleId = ... (optional)

        // Required fields specific to your org settings
        portalUser.LastName = 'User';
        portalUser.CommunityNickname = 'testnickdsfgh';
        
        insert portalUser;

        System.runAs(portalUser) {
            BP_GetAldarExpertsAppointments service = new BP_GetAldarExpertsAppointments();
            service.processRequest(new Map<String, String>(), null);
            
        }
    }
}