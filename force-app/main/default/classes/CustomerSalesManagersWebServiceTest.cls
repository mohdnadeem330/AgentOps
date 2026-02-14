@isTest
public with sharing class CustomerSalesManagersWebServiceTest {
    @isTest
    public static void test() {
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        
        TestObjectsFactory.initializeRestContext(null, '/query/agents');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"customerId": ""}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerSalesManagersWebService.getSalesManagersData();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}