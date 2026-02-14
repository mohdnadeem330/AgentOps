@isTest
private class RemoveCountryCodeFromPhoneInvocableTest {
    
    @isTest
    static void testRemoveCountryCodeWithPlus() {
        RemoveCountryCodeFromPhoneInvocable.Request req = new RemoveCountryCodeFromPhoneInvocable.Request();
        req.countryCode = '1';
        req.fullPhoneNumber = '+1234567890';
        
        List<RemoveCountryCodeFromPhoneInvocable.Request> reqList = new List<RemoveCountryCodeFromPhoneInvocable.Request>{ req };
        
        Test.startTest();
        List<RemoveCountryCodeFromPhoneInvocable.Response> results = RemoveCountryCodeFromPhoneInvocable.removeCountryCode(reqList);
        Test.stopTest();
        
        System.assertEquals('234567890', results[0].cleanPhoneNumber, 'Country code should be removed from phone');
    }
    
    @isTest
    static void testRemoveCountryCodeWithoutPlus() {
        RemoveCountryCodeFromPhoneInvocable.Request req = new RemoveCountryCodeFromPhoneInvocable.Request();
        req.countryCode = '91';
        req.fullPhoneNumber = '911234567890';
        
        List<RemoveCountryCodeFromPhoneInvocable.Request> reqList = new List<RemoveCountryCodeFromPhoneInvocable.Request>{ req };
        
        Test.startTest();
        List<RemoveCountryCodeFromPhoneInvocable.Response> results = RemoveCountryCodeFromPhoneInvocable.removeCountryCode(reqList);
        Test.stopTest();
        
        System.assertEquals('1234567890', results[0].cleanPhoneNumber, 'Country code should be removed from phone');
    }
    
    @isTest
    static void testCountryCodeNotPresent() {
        RemoveCountryCodeFromPhoneInvocable.Request req = new RemoveCountryCodeFromPhoneInvocable.Request();
        req.countryCode = '44';
        req.fullPhoneNumber = '1234567890';
        
        List<RemoveCountryCodeFromPhoneInvocable.Request> reqList = new List<RemoveCountryCodeFromPhoneInvocable.Request>{ req };
        
        Test.startTest();
        List<RemoveCountryCodeFromPhoneInvocable.Response> results = RemoveCountryCodeFromPhoneInvocable.removeCountryCode(reqList);
        Test.stopTest();
        
        System.assertEquals('1234567890', results[0].cleanPhoneNumber, 'Phone number should be unchanged if country code not present');
    }
    
    @isTest
    static void testBlankInputs() {
        RemoveCountryCodeFromPhoneInvocable.Request req = new RemoveCountryCodeFromPhoneInvocable.Request();
        req.countryCode = '';
        req.fullPhoneNumber = '';
        
        List<RemoveCountryCodeFromPhoneInvocable.Request> reqList = new List<RemoveCountryCodeFromPhoneInvocable.Request>{ req };
        
        Test.startTest();
        List<RemoveCountryCodeFromPhoneInvocable.Response> results = RemoveCountryCodeFromPhoneInvocable.removeCountryCode(reqList);
        Test.stopTest();
        
        System.assertEquals('', results[0].cleanPhoneNumber, 'Empty inputs should return empty output');
    }
}