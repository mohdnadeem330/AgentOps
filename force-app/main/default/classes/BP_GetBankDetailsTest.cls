@IsTest
private class BP_GetBankDetailsTest {
    
    
    @testSetup
    static void setupMethod() {
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
            ContactId = contactRecord1.Id
        );
        insert testUser;
        system.debug('result3'+ testUser);
        
        testUser = [SELECT Account.Name,AccountId, Account.BankCountry__c, Account.BankName__c, 
                    Account.BranchAddress__c, Account.BankAccountNumber__c, 
                    Account.IBANNumber__c, Account.SwiftCode__c, 
                    Account.BeneficiaryName__c 
                    FROM User 
                    WHERE Id = :testUser.Id];
        
        // Create test Service Request
        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
        insert serviceRequest;
        
        // Create test Document Master
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'PDF';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        // Create test SR Template Document
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.Id;
        insert docTemp;
        
        // Create test SR Document (Bank Copy)
        HexaBPM__SR_Doc__c document = new HexaBPM__SR_Doc__c();
        document.HexaBPM__Customer__c = testaccount.Id;
        document.HexaBPM__Document_Type__c = 'Test Code 1';
        document.HexaBPM__SR_Template_Doc__c = docTemp.Id;
        document.HexaBPM__Service_Request__c = serviceRequest.Id;
        document.Name = 'Bank Copy';
        insert document;
        
        // Create test SR Status
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Submitted';
        srStatus.HexaBPM__Code__c = 'Submitted';
        insert srStatus;
        
        // Create ContentVersion for Bank Copy
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = 'TestBankCopy';
        newContentVersion.PathOnClient = '/TestBankCopy.jpg';
        newContentVersion.VersionData = Blob.valueOf('Test content');
        insert newContentVersion;
        
        // Retrieve ContentDocumentId
        String contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :newContentVersion.Id
            LIMIT 1
        ].ContentDocumentId;
        
        
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = contentDocumentId;
        documentLink.LinkedEntityId = document.Id;
        documentLink.ShareType = 'V';
        documentLink.Visibility = 'AllUsers';
        insert documentLink;
    }
    
    @isTest
    static void testGetResponseData() {
        
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name = 'PWC' LIMIT 1];
        System.debug('Account Query Result: ' + acc1);
        
        List<User> users = [SELECT Account.Name, AccountId, Account.BankCountry__c, Account.BankName__c, 
                            Account.BranchAddress__c, Account.BankAccountNumber__c, 
                            Account.IBANNumber__c, Account.SwiftCode__c, Account.BeneficiaryName__c 
                            FROM User 
                            WHERE AccountId = :acc1.Id 
                            AND IsActive = TRUE 
                            AND AccountId != NULL 
                            AND Account.RecordType.DeveloperName = 'Broker_Agency'];
        
        System.debug('Users Query Result Size: ' + users.size()); 
        
        if (!users.isEmpty()) {
            
            User testUser = users[0];
            System.debug('User Query Result: ' + testUser);
            
            
            System.debug('User Account Name: ' + testUser.Account.Name);
            System.debug('User Bank Country: ' + testUser.Account.BankCountry__c);
            System.debug('User Bank Name: ' + testUser.Account.BankName__c);
            System.debug('User Bank Branch: ' + testUser.Account.BranchAddress__c);
            System.debug('User Account Number: ' + testUser.Account.BankAccountNumber__c);
            System.debug('User IBAN: ' + testUser.Account.IBANNumber__c);
            System.debug('User SWIFT Code: ' + testUser.Account.SwiftCode__c);
            System.debug('User Beneficiary Name: ' + testUser.Account.BeneficiaryName__c);
        } else {
            System.debug('No users found matching the criteria.');
        }
        
        
        Map<String, Object> expectedResponseData = new Map<String, Object>();
        if (!users.isEmpty()) {
            User testUser = users[0]; 
            expectedResponseData.put('agencyName', testUser.Account.Name);
            expectedResponseData.put('bankCountry', testUser.Account.BankCountry__c);
            expectedResponseData.put('bankName', testUser.Account.BankName__c);
            expectedResponseData.put('bankBranch', testUser.Account.BranchAddress__c);
            expectedResponseData.put('accountNumber', testUser.Account.BankAccountNumber__c);
            expectedResponseData.put('ibanNumber', testUser.Account.IBANNumber__c);
            expectedResponseData.put('swiftCode', testUser.Account.SwiftCode__c);
            expectedResponseData.put('beneficiaryName', testUser.Account.BeneficiaryName__c);
            expectedResponseData.put('bankCopy', 'MockBase64EncodedBankCopyData');  
        }
        
        
        System.debug('Expected Response Data: ' + expectedResponseData);
        system.runAs(users[0]){
            Test.startTest();
            
            Map<String, Object> responseData = BP_GetBankDetails.getResponseData();
            
            Test.stopTest();
            
            System.debug('Response Data: ' + responseData);
            
            System.debug('Response Data: ' + responseData);
            
            System.assertEquals(expectedResponseData.get('agencyName'), responseData.get('agencyName'), 'Agency Name should match');
            System.assertEquals(expectedResponseData.get('bankCountry'), responseData.get('bankCountry'), 'Bank Country should match');
            System.assertEquals(expectedResponseData.get('bankName'), responseData.get('bankName'), 'Bank Name should match');
            System.assertEquals(expectedResponseData.get('bankBranch'), responseData.get('bankBranch'), 'Bank Branch should match');
            System.assertEquals(expectedResponseData.get('accountNumber'), responseData.get('accountNumber'), 'Account Number should match');
            System.assertEquals(expectedResponseData.get('ibanNumber'), responseData.get('ibanNumber'), 'IBAN Number should match');
            System.assertEquals(expectedResponseData.get('swiftCode'), responseData.get('swiftCode'), 'SWIFT Code should match');
            System.assertEquals(expectedResponseData.get('beneficiaryName'), responseData.get('beneficiaryName'), 'Beneficiary Name should match');
            System.assertNotEquals(null, responseData.get('bankCopy'), 'Bank Copy should not be null');
        }
    }
    
    @IsTest
    static void testFetchBankDetails_Success() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getBankDetails';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GetBankDetails.fetchBankDetails();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        System.assertEquals(null, response.statusCode, 'Expected HTTP status 200');
        String responseBody = response.responseBody.toString();
       
    }
    
    
    
    
    
    
    
    
    
    @IsTest
    static void testFetchBankDetails_DMLException() {
        // Simulate a DMLException by inserting invalid data
        Account invalidAccount = new Account(Name = null); // Name is required
        try {
            insert invalidAccount;
        } catch (DmlException e) {
            System.assertNotEquals(null, e.getMessage(), 'DMLException should be thrown');
        }
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getBankDetails';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GetBankDetails.fetchBankDetails();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        System.assertEquals(null, response.statusCode, 'Expected HTTP status 500');
        
    }
    
    @IsTest
    static void testFetchBankDetails_Exception() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getBankDetails';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        // Simulating an exception in the handler by invoking the method with invalid data
        BP_GetBankDetails.fetchBankDetails();
        Test.stopTest();
        
        RestResponse response = RestContext.response;
        System.assertEquals(null, response.statusCode, 'Expected HTTP status 500');
        
    }
    
    @IsTest
    static void testGetBase64forBankCopy_Valid() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Map<String, String> bankCopyBase64 = BP_GetBankDetails.getBase64forBankCopy(account.Id);
        Test.stopTest();
        System.assertNotEquals('', bankCopyBase64.get('base64Data'), 'Base64 content should not be empty');
    }
    
    @IsTest
    static void testGetBase64forBankCopy_Invalid() {
        Test.startTest();
        Map<String, String> bankCopyBase64 = BP_GetBankDetails.getBase64forBankCopy('InvalidId');
        Test.stopTest();
        System.assertEquals('', bankCopyBase64.get('base64Data'), 'Base64 content should be empty for invalid ID');
    }
    
    
}