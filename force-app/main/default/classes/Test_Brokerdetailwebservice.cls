@isTest
private class Test_Brokerdetailwebservice {

    // Helper method to create test Account
    private static Account createTestAccount(String name) {
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Broker_Agency' AND SObjectType = 'Account' 
            LIMIT 1
        ];

        Account acc = new Account(
            Name = name,
            Phone = '1234567890',
            Email__c = 'test@example.com',
            AgencyStatus__c = 'Active',
            RecordTypeId = rt.Id
        );
        insert acc;
        return acc;
    }

    @isTest
    static void testGetAccounts_WithBrokerName() {
        // Arrange
        Account acc = createTestAccount('Test Broker');

        // Set up RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestUri = '/services/apexrest/LiveAldar/BrokerDetailList/';
        RestContext.request.addParameter('BrokerName', 'Test');

        // Act
        Brokerdetailwebservice.getAccounts();

        // Assert
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response: ' + responseBody);
        System.assertNotEquals(null, responseBody, 'Response should not be null');
        System.assert(responseBody.contains('Success'), 'Response should contain "Success"');
        System.assert(responseBody.contains(acc.Id), 'Response should contain the created Account ID');
        System.assert(responseBody.contains(acc.Name), 'Response should contain the created Account Name');
    }

    @isTest
    static void testGetAccounts_WithoutBrokerName() {
        // Arrange
        Account acc = createTestAccount('Any Broker');

        // Set up RestContext without BrokerName param
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestUri = '/services/apexrest/LiveAldar/BrokerDetailList/';

        // Act
        Brokerdetailwebservice.getAccounts();

        // Assert
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response: ' + responseBody);
        System.assertNotEquals(null, responseBody, 'Response should not be null');
        System.assert(responseBody.contains('Success'), 'Response should contain "Success"');
        System.assert(responseBody.contains(acc.Id), 'Response should contain the created Account ID');
    }
}