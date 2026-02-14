@isTest(SeeAllData=false)
public class ConfigurationsWebServiceTest {
    @isTest static void setupMethod() {
        Datetime latestDate = Datetime.newInstance(2020, 06, 03);
        
        ConfigurationsWebService.ConfigurationsResponse configurationsResponse = new ConfigurationsWebService.ConfigurationsResponse();

        TestObjectsFactory.initializeRestContext(null, '/configurations');
        ConfigurationsWebService.doPost(latestDate);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);

        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/configurations');
        ConfigurationsWebService.doPost(latestDate);
        
        List<String> currencyValues = ConfigurationsWebService.getCurrencyValues(configurationsResponse);
        
        //TestObjectsFactory.initializeRestContext(null, '/configurationsss');
        //ConfigurationsWebService.doPost(latestDate);
        Test.stopTest();

    }
}