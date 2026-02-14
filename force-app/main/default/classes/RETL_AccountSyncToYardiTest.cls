@IsTest
private class RETL_AccountSyncToYardiTest {

    // ------------------------------------------------------------
    // MOCK CALLOUT
    // ------------------------------------------------------------
    private class MockCallout implements HttpCalloutMock {
        private Id accountId;

        public MockCallout(Id accountId){
            this.accountId = accountId;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '{' +
                '"Yardi_Customer_Code":"Y99999",' +
                '"Status":"Success",' +
                '"ErrorMessage":null,' +
                '"SF_Ref_Customer_Id":"' + accountId + '"' +
            '}';
            res.setBody(body);
            return res;
        }
    }

    // ------------------------------------------------------------
    // TEST DATA
    // ------------------------------------------------------------
    private static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Test Customer',
            Type = 'Retail',
            RETL_Status__c = 'Active',
            RETL_SalesCategory__c = 'A',
            Description = 'Notes...',
            UAEVATRegisterNumber__c = 'VAT-123',
            RETL_Tax_Authority__c = 'FTA'
        );
        insert acc;
        return acc;
    }

    // ------------------------------------------------------------
    // TEST: pushToYardiAndUpdate (Success)
    // ------------------------------------------------------------
    @IsTest
    static void testPushToYardiAndUpdate_Success() {
        Account acc = createTestAccount();

        Test.setMock(HttpCalloutMock.class, new MockCallout(acc.Id));

        Test.startTest();
        RETL_AccountSyncToYardi.pushToYardiAndUpdate(acc.Id);
        Test.stopTest();

        Account updatedAcc = [SELECT RETL_Yardi_Id__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Y99999', updatedAcc.RETL_Yardi_Id__c);
    }

    // ------------------------------------------------------------
    // TEST: pushToYardiAsync (future method)
    // ------------------------------------------------------------
    @IsTest
    static void testPushToYardiAsync() {
        Account acc = createTestAccount();

        Test.setMock(HttpCalloutMock.class, new MockCallout(acc.Id));

        Test.startTest();
        RETL_AccountSyncToYardi.pushToYardiAsync(acc.Id);
        Test.stopTest();

        Account updatedAcc = [SELECT RETL_Yardi_Id__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Y99999', updatedAcc.RETL_Yardi_Id__c);
    }

    // ------------------------------------------------------------
    // TEST: Null Account Id
    // ------------------------------------------------------------
    @IsTest
    static void testPushToYardiAndUpdate_NullAccountId() {
        Test.startTest();
        try {
            RETL_AccountSyncToYardi.pushToYardiAndUpdate(null);
            System.assert(false, 'Expected CustomException was not thrown');
        } catch (RETL_AccountSyncToYardi.CustomException e) {
            System.assertEquals('Account Id cannot be null.', e.getMessage());
        }
        Test.stopTest();
    }

    // ------------------------------------------------------------
    // TEST: buildAccountWrapper()
    // ------------------------------------------------------------
    @IsTest
    static void testBuildAccountWrapper() {
        Account acc = createTestAccount();

        RETL_AccountSyncToYardi.YardiCustomerRequestWrapper wrapper =
            RETL_AccountSyncToYardi.buildAccountWrapper(acc.Id);

        System.assertEquals(1, wrapper.Customer.size(), 'Should contain one customer');
        System.assertEquals(acc.Id, wrapper.Customer[0].SF_Ref_Customer_Id);
        System.assertEquals(acc.Name, wrapper.Customer[0].Customer_Name);
        System.assertEquals('Active', wrapper.Customer[0].Customer_Status);
    }

    // ------------------------------------------------------------
    // TEST: Flow method
    // ------------------------------------------------------------
    /* @IsTest
    static void testPushAccountToYardiFromFlow() {

        Account acc = createTestAccount();
        Test.setMock(HttpCalloutMock.class, new MockCallout(acc.Id));

        RETL_AccountSyncToYardi.FlowInput input = new RETL_AccountSyncToYardi.FlowInput();
        input.accountId = acc.Id;
        input.isSandbox = true;

        List<RETL_AccountSyncToYardi.FlowInput> listInput = new List<RETL_AccountSyncToYardi.FlowInput>{ input };

        Test.startTest();
        List<RETL_AccountSyncToYardi.FlowOutput> outputs =
            RETL_AccountSyncToYardi.pushAccountToYardiFromFlow(listInput);
        Test.stopTest();

        System.assertEquals('Success', outputs[0].status);
        System.assertEquals('Y99999', outputs[0].yardiCustomerCode);

        Account updatedAcc = [SELECT RETL_Yardi_Id__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Y99999', updatedAcc.RETL_Yardi_Id__c);
    } */


    private class MockErrorCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(500);
            res.setBody('{"Status":"Failed","ErrorMessage":"Server error"}');
            return res;
        }
    }

    @IsTest
    static void testPushToYardiAndUpdate_HttpError() {
        Account acc = createTestAccount();

        // Use the ERROR mock, NOT anonymous class
        Test.setMock(HttpCalloutMock.class, new MockErrorCallout());

        Test.startTest();
            RETL_AccountSyncToYardi.pushToYardiAndUpdate(acc.Id);
        Test.stopTest();

        // Ensure Account NOT updated
        Account accAfter = [SELECT RETL_Yardi_Id__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            null,
            accAfter.RETL_Yardi_Id__c,
            'Account Yardi Id should NOT be updated for statusCode >= 300'
        );
    }

    private class MockYardiFailureCallout implements HttpCalloutMock {
        private Id accountId;

        public MockYardiFailureCallout(Id accountId){
            this.accountId = accountId;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(200); // Success HTTP, but Yardi failed

            // Either Status = 'Failed' or Yardi_Customer_Code is blank
            String body = '{' +
                '"Yardi_Customer_Code": "",' +
                '"Status": "Failed",' +
                '"ErrorMessage": "Invalid customer data",' +
                '"SF_Ref_Customer_Id":"' + accountId + '"' +
            '}';
            res.setBody(body);
            return res;
        }
    }


    @IsTest
    static void testPushToYardiAndUpdate_YardiFailed() {
        // Create test account
        Account acc = createTestAccount();

        // Use the failure mock
        Test.setMock(HttpCalloutMock.class, new MockYardiFailureCallout(acc.Id));

        Test.startTest();
            RETL_AccountSyncToYardi.pushToYardiAndUpdate(acc.Id);
        Test.stopTest();

        // Account should NOT be updated with Yardi Id
        Account accAfter = [SELECT RETL_Yardi_Id__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            null,
            accAfter.RETL_Yardi_Id__c,
            'Account Yardi Id should NOT be updated if Yardi response Status != Success or code is blank'
        );
    }
}