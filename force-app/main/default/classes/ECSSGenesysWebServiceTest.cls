@isTest
public class ECSSGenesysWebServiceTest {

    @testSetup
    static void setupTestData() {
        Account account1 = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonMobilePhone = '1234567890',
            ECSS_VIP__c = true
        );
        Account account2 = new Account(
            FirstName = 'Jane',
            LastName = 'Smith',
            PersonMobilePhone = '1234567890',
            ECSS_VIP__c = false
        );
        insert new List<Account>{account1, account2};
    }

    @isTest
    static void testDoPostValidPhoneNumber() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('"1234567890"');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ECSSGenesysWebService.doPost('1234567890');
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response Body: ' + responseBody);
        System.assert(responseBody.contains('"totalSize":2'), 'Total size should be 2');
    }

    @isTest
    static void testDoPostInvalidPhoneNumber() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('"0000000000"');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ECSSGenesysWebService.doPost('0000000000');
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response Body: ' + responseBody);
        System.assert(responseBody.contains('"totalSize":0'), 'Total size should be 0');
    }

    @isTest
    static void testDoPostNullPhoneNumber() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('null');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ECSSGenesysWebService.doPost(null);
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"totalSize":0'), 'Total size should be 0');
    }
}