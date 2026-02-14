@isTest
private class BP_UpdateBankDetailsTest {

    // Setup method for reusable test data
    private static Map<String, Object> setupTestData() {
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Agency',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Broker_Agency' LIMIT 1].Id
        );
        insert testAccount;

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

        return new Map<String, Object> {
            'account' => testAccount,
            'contact' => contactRecord1,
            'user' => testUser
        };
    }

    @isTest
    static void testUpdateBankDetailsValidRequest() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');

        // Valid request body
        String requestBody = '{"bankName":"NBD","bankBranch":"ABU DHABI","accountNumber":"110011","ibanNumber":"AE32938232932389238","swiftCode":"NBD111111","bankCountry":"United Arab Emirates","currency":"AED","beneficiaryName":"John Doe","bankCopy":"bankDocumentBase64"}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();

            
        }
        Test.stopTest();
    }
	
    @isTest
    static void testUpdateBankDetailsValidRequestEmptyBank() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');

        // Valid request body
        String requestBody = '{"bankName":"NBD","bankBranch":"ABU DHABI","accountNumber":"110011","ibanNumber":"AE32938232932389238","swiftCode":"NBD111111","bankCountry":"United Arab Emirates","currency":"AED","beneficiaryName":"John Doe","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();

            
        }
        Test.stopTest();
    }

	@isTest
    static void testUpdateBankDetailsValidRequestEmptyBank2() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');

        // Valid request body
        String requestBody = '{"bankName":"NBD","bankBranch":"ABU DHABI","accountNumber":"","ibanNumber":"","swiftCode":"NBD111111","bankCountry":"India","currency":"AED","beneficiaryName":"John Doe","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();

            
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateBankDetailsNullRequestBody() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = null;
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();

             }
        Test.stopTest();
    }

    @isTest
    static void testUpdateBankDetailsNullParamRequestBody() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');
        String requestBody = '{"bankName":"","bankBranch":"","accountNumber":"","ibanNumber":"","swiftCode":"","bankCountry":"United Arab Emirates","currency":"","beneficiaryName":"","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();

               }
        Test.stopTest();
    }

    @isTest
    static void testFutureUploadDocument() {
        Account testAccount = new Account(Name = 'Test Account', Phone = '123456789');
        insert testAccount;

        String profileImage = '/9j/4AAQSkZJRgABAQEASABIAAD...'; // Base64 image string

        Test.startTest();
        new BP_UpdateBankDetails().uploadDocument(profileImage,'Test','.pdf', testAccount.Id);
        Test.stopTest();

        List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title = 'Bank Copy.pdf'];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion record was created as expected.');
    }
	
     @isTest
    static void testFutureUploadDocumentInvalid() {
        Account testAccount = new Account(Name = 'Test Account', Phone = '123456789');
        insert testAccount;

        String profileImage = '/9j/4AAQSkZJRgABAQEASABIAAD...'; // Base64 image string

        Test.startTest();
        new BP_UpdateBankDetails().uploadDocument(null,null,null,null);
        Test.stopTest();

        List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title = 'Bank Copy.pdf'];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion record was created as expected.');
    }

    @isTest
    static void testUpdateNonUAEBankDetailsRequestBody() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');
        String requestBody = '{"bankName":"","bankBranch":"","accountNumber":null,"ibanNumber":"","swiftCode":"","bankCountry":"India","currency":"","beneficiaryName":"","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(requestBody);
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();


        }
        Test.stopTest();
    }

	 @isTest
    static void testUpdateNonUAEBankDetailsRequestBodyInvalid() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');
        String requestBody = '{"bankName":"","bankBranch":"","accountNumber":null,"ibanNumber":"","swiftCode":"","bankCountry":"India","currency":"","beneficiaryName":"","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody =null;
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();


        }
        Test.stopTest();
    }

	 @isTest
    static void testUpdateNonUAEBankDetailsRequestBodyInvalidNull() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        User testUser = (User) testData.get('user');
        //String requestBody = '{"bankName":"","bankBranch":"","accountNumber":null,"ibanNumber":"","swiftCode":"","bankCountry":"India","currency":"","beneficiaryName":"","bankCopy":""}';

        Test.startTest();
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            req.requestBody =Blob.valueOf('');
            req.httpMethod = 'POST';
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            BP_UpdateBankDetails.updateBankDetails();


        }
        Test.stopTest();
    }
}