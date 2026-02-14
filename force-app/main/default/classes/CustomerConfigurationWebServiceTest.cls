@isTest
public class CustomerConfigurationWebServiceTest {

    @isTest
    public static void testCustomerConfigurationWebService() {
        
        TestObjectsFactory.initializeRestContext(null, '/query/configurations');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerConfigurationWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}