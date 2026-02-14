@IsTest
private class PremPark_OrderIntegrationControllerTest {
    
    public class PremPark_OrderIntegrationMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"applicationName": "PremPark","success": true,"statusCode": 200,"correlationId": "123-456-789","results": [{"sfRequestId": "123456","sfOrderId": "*","status": "ERP_ORDER_STATUS","errorMsg": null,"erpID": "1234567"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contract
        Contract testContract = new Contract(AccountId = testAccount.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
        insert testContract;

        // Activate the Contract
        testContract.Status = 'Activated';
        update testContract;

        // Create a test Order
        Order testOrder = new Order(AccountId = testAccount.Id, ContractId = testContract.Id, EffectiveDate = Date.today(), Status = 'Draft');
        insert testOrder;

        // Create a test Attachment
        Attachment testAttachment = new Attachment(ParentId = testOrder.Id, Name = 'Test Attachment', Body = Blob.valueOf('Test Attachment Content'));
        insert testAttachment;
    }

    @IsTest
    static void testPushOrderToERP() {
        // Get the test Order record
        Order testOrder = [SELECT Id, AccountId FROM Order LIMIT 1];

        // Set up the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new PremPark_OrderIntegrationMock());

        // Start the test
        Test.startTest();

        // Call the method to test
        PremPark_OrderIntegrationController.pushOrderToERP(new Set<Id>{testOrder.Id});

        // Stop the test
        Test.stopTest();

        // Verify that the Account Id is not null
        System.assertNotEquals(null, testOrder.AccountId, 'Account Id should not be null.');
    }
}