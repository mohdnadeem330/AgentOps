@isTest
public class UpdateAgentStatusWebServiceTest {
    @isTest static void setupMethod() {

        TestObjectsFactory.initializeRestContext(null, '/update/status');
        UpdateAgentStatusWebService.doPost('Offline');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);

        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/update/status');
        UpdateAgentStatusWebService.doPost('Available');
        Test.stopTest();


    }
}