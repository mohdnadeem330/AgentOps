@isTest
public class BP_ManageBrokerCasesTest { 
     // Setup method to create test data
     // Test setup method to create test data
    @TestSetup
    static void setupData() {
        // Create Parent Account
        Account parentAccount = new Account(
            Name = 'Parent Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Broker_Agency' LIMIT 1].Id
        );
        insert parentAccount;
        
        // Create Child Account linked to Parent Account
        Account childAccount = new Account(
            Name = 'Child Account',
            ParentId = parentAccount.Id, // Link to Parent Account
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Broker_Agency' LIMIT 1].Id
        );
        insert childAccount;
        
        // Create Contact linked to Child Account
        Contact childContact = new Contact(
            LastName = 'Child Contact',
            AccountId = childAccount.Id,
            PrimaryAgencyAdmin__c = true,
            AgentStatus__c = 'Active',
            MobileCountryCode__c = '971',
            MobilePhone__c = '9696859685',
            Email = 'childcontact@gmail.com',
            BrokerType__c = 'Partner/Owner',
            PrimaryOwner__c = true
        );
        insert childContact;
        
         Contact childContact1 = new Contact(
            LastName = 'Child Contact1',
            AccountId = childAccount.Id,
            PrimaryAgencyAdmin__c = true,
            AgentStatus__c = 'Active',
            MobileCountryCode__c = '971',
            MobilePhone__c = '9696859687',
            Email = 'childcontactt@gmail.com',
            BrokerType__c = 'Partner/Owner',
            PrimaryOwner__c = true
        );
        insert childContact1;


        // Create Case for the Parent Account
        Case parentCase = new Case(
            RecordTypeId = Schema.getGlobalDescribe()
                .get('Case')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('BrokerCase')
                .getRecordTypeId(),
            Subject = 'Parent Case Subject',
            Description = 'Parent Case Description',
            Status = 'New',
            Category__c = 'Compliance',
            ContactId = childContact1.Id,
            AccountId = parentAccount.Id
        );
        insert parentCase;
        
        // Create Case for the Child Account
        Case childCase = new Case(
            RecordTypeId = Schema.getGlobalDescribe()
                .get('Case')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('BrokerCase')
                .getRecordTypeId(),
            Subject = 'Child Case Subject',
            Description = 'Child Case Description',
            Status = 'New',
            Category__c = 'Compliance',
            ContactId = childContact.Id,
            AccountId = childAccount.Id
        );
        insert childCase;

        // Create ContentVersion (File for Case)
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = 'TestFileForCase';
        newContentVersion.PathOnClient = '/TestFile.jpg';
        newContentVersion.VersionData = Blob.valueOf('Test content');
        insert newContentVersion;
        
        // Retrieve ContentDocumentId
        String contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :newContentVersion.Id
            LIMIT 1
        ].ContentDocumentId;

        // Create ContentDocumentLink
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = contentDocumentId;
        documentLink.LinkedEntityId = childCase.Id;  // Link to the case
        documentLink.ShareType = 'V';
        documentLink.Visibility = 'AllUsers';
        insert documentLink;
        
        // Create a test User
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Agency Admin' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            ContactId = childContact.Id
        );
        insert testUser;
        
        
        // Create a test User
        Profile userProfile1 = [SELECT Id FROM Profile WHERE Name = 'Agency User' LIMIT 1];
        User testUser1 = new User(
            FirstName = 'Test1',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile1.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            ContactId = childContact1.Id
        );
        insert testUser1;
    }

    @isTest
    static void testUpdateBankDetailsValidRequest() {
        // Retrieve Parent Account, Child Account, and associated records
        Account parentAccount = [SELECT Id, Name FROM Account WHERE Name = 'Parent Account' LIMIT 1];
        Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = 'Child Account' LIMIT 1];
        Contact childContact = [SELECT Id, AccountId FROM Contact WHERE AccountId = :childAccount.Id LIMIT 1];
        Case parentCase = [SELECT Id, Subject, AccountId,ContactId FROM Case WHERE AccountId = :parentAccount.Id LIMIT 1];
        Case childCase = [SELECT Id, Subject, AccountId, ContactId FROM Case WHERE AccountId = :childAccount.Id AND Subject= 'Child Case Subject' LIMIT 1];
        ContentDocumentLink docLink = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :childCase.Id LIMIT 1];

     
        List<Case> allCases = [SELECT Id FROM Case WHERE AccountId IN :new Set<Id> { parentAccount.Id, childAccount.Id }];
        Map<Id, Case> caseWithFiles = new Map<Id, Case>(allCases);

        System.debug('All Cases: ' + allCases); 
        
       
        System.assertNotEquals(docLink, null, 'ContentDocumentLink should exist');
        System.assertEquals(caseWithFiles.size(), 2, 'Two cases should be returned');
       

        // Test the logic using the user
        User testUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        System.debug('Test User: ' + testUser);
        
        List<User> users = [SELECT Id FROM User WHERE AccountId = :childAccount.Id AND IsActive = TRUE];
        system.runAs(users[0]) {
            
            String requestBody = '{"category":"Compliance","status":"New","searchKey":"Case","limits":100,"offsets":0}';
            Test.startTest();
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            // Execute the logic
            BP_ManageBrokerCases.excute();  // Call the actual method being tested

            
            Test.stopTest();
        }
    }
    
    
    
        @isTest
    static void testUpdateBankDetailsValidRequest1() {
        // Retrieve Parent Account, Child Account, and associated records
        Account parentAccount = [SELECT Id, Name FROM Account WHERE Name = 'Parent Account' LIMIT 1];
        Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = 'Child Account' LIMIT 1];
        Contact childContact = [SELECT Id, AccountId FROM Contact WHERE lastName = 'Child Contact1' LIMIT 1];
        Case parentCase = [SELECT Id, Subject, AccountId,ContactId FROM Case WHERE AccountId = :parentAccount.Id LIMIT 1];
        Case childCase = [SELECT Id, Subject, AccountId, ContactId FROM Case WHERE AccountId = :childAccount.Id LIMIT 1];
        ContentDocumentLink docLink = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :childCase.Id LIMIT 1];

     
        List<Case> allCases = [SELECT Id FROM Case WHERE AccountId IN :new Set<Id> { parentAccount.Id, childAccount.Id }];
        Map<Id, Case> caseWithFiles = new Map<Id, Case>(allCases);

        System.debug('All Cases: ' + allCases); 
        
       
        System.assertNotEquals(docLink, null, 'ContentDocumentLink should exist');
        System.assertEquals(caseWithFiles.size(), 2, 'Two cases should be returned');
       

        // Test the logic using the user
        User testUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'testuser1@example.com' LIMIT 1];
        System.debug('Test User: ' + testUser);
        
        List<User> users = [SELECT Id FROM User WHERE AccountId = :childAccount.Id AND IsActive = TRUE];
        system.runAs(testUser) {
            
            String requestBody = '{"category":"Compliance","status":"New","searchKey":"Case","limits":100,"offsets":0}';
            Test.startTest();
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            // Execute the logic
            BP_ManageBrokerCases.excute();  // Call the actual method being tested

            
            Test.stopTest();
        }
    }
    
    
    
    
    
    
    @isTest
    static void testUpdateBankDetailsNullRequestBody() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        system.runAs(users[0]) {
            Test.startTest();
            RestRequest req = new RestRequest();
            req.requestBody = null; 
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_ManageBrokerCases.excute();

            // Add Assertions here if necessary
            Test.stopTest();
        }
    }

     
    
    
    
    @isTest
    static void testUpdateNonUAEBankDetailsRequestBody() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        system.runAs(users[0]) {
            String requestBody = '{"category":"InvalidCategory","status":"New","searchKey":"Case","limits":100,"offsets":0}';
            Test.startTest();
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody); 
            req.httpMethod = 'POST';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            BP_ManageBrokerCases.excute();
            
            // Add Assertions here if necessary
            Test.stopTest();
        }
    }
}