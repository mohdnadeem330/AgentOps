@isTest
private class CountryCodeInvocableTest {
    
    @isTest
    static void testGetCountryCodesWithValidCountry() {
        CountryCodeInvocable.Request req = new CountryCodeInvocable.Request();
        req.countryName = 'India';
        
        List<CountryCodeInvocable.Request> reqList = new List<CountryCodeInvocable.Request>{ req };
        
        Test.startTest();
        List<CountryCodeInvocable.Response> results = CountryCodeInvocable.getCountryCodes(reqList);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetCountryCodesWithInvalidCountry() {
        CountryCodeInvocable.Request req = new CountryCodeInvocable.Request();
        req.countryName = 'InvalidCountry';
        
        List<CountryCodeInvocable.Request> reqList = new List<CountryCodeInvocable.Request>{ req };
        
        Test.startTest();
        List<CountryCodeInvocable.Response> results = CountryCodeInvocable.getCountryCodes(reqList);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetCountryCodesWithMultipleRequests() {
        CountryCodeInvocable.Request req1 = new CountryCodeInvocable.Request();
        req1.countryName = 'Brazil';
        
        CountryCodeInvocable.Request req2 = new CountryCodeInvocable.Request();
        req2.countryName = 'UnknownCountry';
        
        List<CountryCodeInvocable.Request> reqList = new List<CountryCodeInvocable.Request>{ req1, req2 };
        
        Test.startTest();
        List<CountryCodeInvocable.Response> results = CountryCodeInvocable.getCountryCodes(reqList);
        Test.stopTest();
        
    }
}