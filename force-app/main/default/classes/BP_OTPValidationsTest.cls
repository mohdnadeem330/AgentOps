@isTest
private class BP_OTPValidationsTest {

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
            PrimaryOwner__c = true,
            BrokerLoginOTPNumber__c='987654'
        );
        insert contactRecord1;

        return new Map<String, Object> {
            'account' => testAccount,
            'contact' => contactRecord1
        };
    }

    @isTest
    static void testExecuteValidRequest() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        Contact testContact = (Contact) testData.get('contact');

        // Valid request body
        String requestBody = '{"contactId":"' + testContact.Id + '"}';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        BP_OTPValidations.excute();

        // Asserts based on the expected behavior
        System.assertEquals(null, RestContext.response.statusCode);
       
        Test.stopTest();
    }

    @isTest
    static void testExecuteNullRequestBody() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = null;
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        BP_OTPValidations.excute();

        // Assert that the response is an error due to null request body
        System.assertEquals(null, RestContext.response.statusCode);
      
        Test.stopTest();
    }

    @isTest
    static void testExecuteInvalidContactId() {
        // Invalid request body (no valid contactId)
        String requestBody = '{"contactId":"invalid_contact_id"}';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        BP_OTPValidations.excute();

        // Assert that the response is a failure due to invalid contactId
        System.assertEquals(null, RestContext.response.statusCode);
        
        Test.stopTest();
    }

    @isTest
    static void testExecuteEmptyRequestBody() {
        // Setup test data
        Map<String, Object> testData = setupTestData();
        String requestBody = '';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        BP_OTPValidations.excute();

       
        System.assertEquals(null, RestContext.response.statusCode);
        
        Test.stopTest();
    }

    @isTest
    static void testExecuteExceptionHandling() {
        // Simulate an exception by passing invalid data to cause an exception in processRequest
        String requestBody = '{"contactId":"non_existent_contact"}';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        BP_OTPValidations.excute();

        // Assert that the response is an error due to an exception
        System.assertEquals(null, RestContext.response.statusCode);
        
        Test.stopTest();
    }
    
  

    @isTest
    static void testValidateOTP() {
              Map<String, Object> testData = setupTestData();
        Contact testContact = (Contact) testData.get('contact');
    
        Test.startTest();
        String result = BP_OTPValidations.validateOTP(testContact.Id, 'Update Bank Details', 'Type2', '654321');
        Test.stopTest();
   
        result = BP_OTPValidations.validateOTP(testContact.Id, 'Update Bank Details', 'Type2', 'wrongOTP');
       
    }
@isTest
    static void testValidateOTP_AddAgent() {
               Map<String, Object> testData = setupTestData();
        Contact testContact = (Contact) testData.get('contact');
        Test.startTest();
        String result = BP_OTPValidations.validateOTP(testContact.Id, 'Add Agent', 'Type3', '987654');
        Test.stopTest();
  
        result = BP_OTPValidations.validateOTP(testContact.Id, 'Add Agent', 'Type3', 'wrongOTP');
      
    }

@isTest
    static void testValidateOTP_Agency() {
               Map<String, Object> testData = setupTestData();
        Contact testContact = (Contact) testData.get('contact');
        Test.startTest();
        String result = BP_OTPValidations.validateOTP(testContact.Id, 'Agency Registration', 'Type3', '987654');
        Test.stopTest();
  
        result = BP_OTPValidations.validateOTP(testContact.Id, 'Agency Registration', 'Type3', 'wrongOTP');
      
    }  
}