@isTest
public class MobileNumberValidationTest {
    @isTest
    public static void testValidatePhoneNo() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MobileMockHttpResponseGenerator());

        // Prepare test data
        List<String> phoneNumbers = new List<String>{'971528843730'}; // Replace with valid test phone numbers

        // Call the method to be tested
        Map<String, String> result = MobileNumberValidation.validatePhoneNo(phoneNumbers);
system.debug('result '+result);
        // Perform assertions based on the expected response from the mocked HTTP response
//        System.assertEquals('ExpectedCountryPrefix', result.get('CountryPrefix'));
//        System.assertEquals('ExpectedNationalFormat', result.get('NationalFormat'));
//        System.assertEquals('ExpectedIsValid', result.get('IsValid'));
    }
}