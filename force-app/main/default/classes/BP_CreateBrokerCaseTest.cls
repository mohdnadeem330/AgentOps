@isTest 
public class BP_CreateBrokerCaseTest {
    @TestSetup
    static void setupData() {
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        accountRecord.OwnerId = UserInfo.getUserId();
        insert accountRecord;
        
        Contact con = new Contact();
        con.LastName = 'Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';
        con.Phone = '527583669';
        con.OwnerId = UserInfo.getUserId();
        con.MobilePhone = '527583669';
        insert con;
        
        Case newCase = new Case(
            RecordTypeId = Schema.getGlobalDescribe()
                .get('Case')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('BrokerCase')
                .getRecordTypeId(),
            Subject = 'Test Subject',
            Description = 'Test Description',
            Status = 'New',
            Origin = 'Broker Portal',
            AccountId = accountRecord.Id,
            ContactId = con.Id,
            Category__c = 'Compliance'
        );
        insert newCase;
        
        TestObjectsFactory.createContentDocumentLink(newCase.Id);
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
        agencyAdmin.Email = 'testuser@example.com';
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.isActive = true;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert agencyAdmin;
        }
    }

    @isTest
    static void testCreateCaseSuccess() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CompanyName' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(testUser) {
            BP_CreateBrokerCase.FileToInsert file = new BP_CreateBrokerCase.FileToInsert();
            file.title = 'Test File';
            file.versionData = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

            BP_CreateBrokerCase.WrapperClass wrapper = new BP_CreateBrokerCase.WrapperClass();
            wrapper.caseRec = new Case(
                Subject = 'API Created Case',
                Description = 'Created via API',
                Status = 'New',
                AccountId = acc.Id,
                ContactId = con.Id,
                Category__c = 'Compliance'
            );
            wrapper.filesToInsert = new List<BP_CreateBrokerCase.FileToInsert>{ file };

            simulateRequest(wrapper);
            Test.startTest();
            BP_CreateBrokerCase.execute();
            Test.stopTest();

            validateResponse(true);
        }
    }

    @isTest
    static void testAddCommentToCase() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        BP_CreateBrokerCase.WrapperClass wrapper = new BP_CreateBrokerCase.WrapperClass();
        wrapper.caseId = testCase.Id;
        wrapper.comment = 'Test Comment';

        simulateRequest(wrapper);
        Test.startTest();
        BP_CreateBrokerCase.execute();
        Test.stopTest();

        validateResponse(true);
    }

    @isTest
    static void testAddFilesToCase() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        BP_CreateBrokerCase.FileToInsert file = new BP_CreateBrokerCase.FileToInsert();
        file.title = 'File Upload';
        file.versionData = EncodingUtil.base64Encode(Blob.valueOf('File content'));

        BP_CreateBrokerCase.WrapperClass wrapper = new BP_CreateBrokerCase.WrapperClass();
        wrapper.caseId = testCase.Id;
        wrapper.filesToInsert = new List<BP_CreateBrokerCase.FileToInsert>{ file };

        simulateRequest(wrapper);
        Test.startTest();
        BP_CreateBrokerCase.execute();
        Test.stopTest();

        validateResponse(true);
    }

    @isTest
    static void testInvalidRequest() {
        BP_CreateBrokerCase.WrapperClass wrapper = new BP_CreateBrokerCase.WrapperClass(); // Empty request

        simulateRequest(wrapper);
        Test.startTest();
        BP_CreateBrokerCase.execute();
        Test.stopTest();

        validateResponse(false);
    }

    // Helper Methods
    private static void simulateRequest(BP_CreateBrokerCase.WrapperClass wrapper) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void validateResponse(Boolean isSuccessExpected) {
        String responseBody = RestContext.response.responseBody.toString();
        System.assertNotEquals(null, responseBody, 'Response body should not be null');

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assertEquals(isSuccessExpected, responseMap.get('success'), 'Success flag mismatch');
    }
}