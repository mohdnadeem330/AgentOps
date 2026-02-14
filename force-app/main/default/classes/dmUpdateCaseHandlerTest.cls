//Harsh@Aldar 26/05/2025 Added SeeAllData True
//ConnectApi methods are not supported in data siloed tests
//https://ideas.salesforce.com/s/idea/a0B8W00000GdZzDUAV/fix-connectapi-methods-are-not-supported-in-data-siloed-tests?sfdcIFrameOrigin=null
@isTest(SeeAllData=true)
public class dmUpdateCaseHandlerTest {
    
	@isTest
    static void testPostToChatter() {
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Subject = 'Test NOC Application',
            Sub_Status__c = 'Documents Accepted by PMC',
            Status = 'Work In Progress',
            Development_Name__c='Saadiyat Island',
            Assigned_To__c = testUser.Id
            
        );
        insert testCase;

        // Call the method
        Test.startTest();
        dmUpdateCaseHandler.postToChatter(testCase.Id, testUser.Id, 'This is a test feed message');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCase() {
        // Create and insert a test profile
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create and insert a test user
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser56748@test.com'
        );
        insert testUser;
        
        // Create and insert an approver user
        User approverUser = new User(
            Alias = 'approv1',
            Email = 'approver1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Approver',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'approver100651@test.com',
            IsActive = true
        );
        insert approverUser;
        
        // Create a test case
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Subject = 'Test NOC Application',
            Sub_Status__c = 'Documents Accepted by PMC',
            Status = 'Work In Progress',
             Development_Name__c='Saadiyat Island',
            Assigned_To__c = approverUser.Id
            
        );
        insert testCase;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(testCase.id);
        app.setNextApproverIds(new List<Id>{approverUser.id});
        Approval.ProcessResult result = Approval.process(app);
        Test.startTest();
        dmUpdateCaseHandler.updateCase(testCase, 'Test feed message', testUser.Id, 'Approve', approverUser.Id, testCase.CaseNumber);
        
        Test.stopTest();       
    }
    
    
    @isTest
    static void testGetSubStatusDetails() {
        // Test data setup
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser5467@test.com'
        );
        insert testUser;
        
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id);
        insert testContact;
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Development_Name__c='Yas Island'
        );
        insert testCase;
        
        Generic_Sub_Status_Config__mdt subStatusConfig = new Generic_Sub_Status_Config__mdt(
            MasterLabel = 'Test Sub Status',
            NextApplicableStatus__c = 'Next Status',
            Reject_Reasons__c = 'Reason1, Reason2',
            Sobject__c = 'Case',
            User_Identifier__c = 'Standard User'
        );
        
        
        Test.startTest();
        System.runAs(testUser) {
            List<Generic_Sub_Status_Config__mdt> result = dmUpdateCaseHandler.getSubStatusDetails(testCase.Id, 'Case');
            Test.stopTest();
            
        }
    }
    
    @isTest
    static void testGetDMApproverUsers() {
        // Mock the custom label value
        List<String> mockApproverUsernames = new List<String>{'approver1@test.com', 'approver2@test.com'};
            
            User approver1 = new User(
                Alias = 'approv1',
                Email = 'approver1@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Approver',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'approver10005@test.com',
                IsActive = true
            );
        User approver2 = new User(
            Alias = 'approv2',
            Email = 'approver2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Approver',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'approver20002@test.com',
            IsActive = true
        );
        insert new List<User>{approver1, approver2};
            
            Test.startTest();
        List<User> result = dmUpdateCaseHandler.getDMApproverUsers();
        Test.stopTest();   
    }
    
    @isTest
    static void testGetDMFinalApproverUserInfo() {
        // Mock the custom label value
        List<String> mockFinalApproverUsernames = new List<String>{'finalapprover1@test.com', 'finalapprover2@test.com'};
            
            User finalApprover1 = new User(
                Alias = 'fapprov1',
                Email = 'finalapprover1@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'FinalApprover',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'finalapprover1@test.com',
                IsActive = true
            );
        User finalApprover2 = new User(
            Alias = 'fapprov2',
            Email = 'finalapprover2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'FinalApprover',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'finalapprover2@test.com',
            IsActive = true
        );
        insert new List<User>{finalApprover1, finalApprover2};
            
            Test.startTest();
        List<User> result = dmUpdateCaseHandler.getDMFinalApproverUserInfo();
        Test.stopTest();
    }
}