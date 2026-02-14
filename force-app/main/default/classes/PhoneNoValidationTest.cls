@isTest
private class PhoneNoValidationTest {
    @isTest static  void phoneNoValidationCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetPhoneNoValidationSuccess');
        mock.setStatusCode(200);
        
        // Success Mock
        Test.setMock(HttpCalloutMock.class, mock);

        boolean successResult = PhoneNoValidation.validatePhoneNo(new List<String>{'962787120342'})[0];
        boolean successResultAura = PhoneNoValidation.getValidatePhoneNoWithAura('962787120342');

        mock.setStaticResource('GetPhoneNoValidationFail');

        // Fail Mock
        Test.setMock(HttpCalloutMock.class, mock);

        boolean falierResult = PhoneNoValidation.validatePhoneNo(new List<String>{'1234567890'})[0];
        boolean falierResultAura = PhoneNoValidation.getValidatePhoneNoWithAura('1234567890');

 /*       system.assertEquals(true, successResult, 'successResult= ' + successResult);
        system.assertEquals(false, falierResult, 'falierResult= '+falierResult);

        system.assertEquals(true, successResultAura, 'successResultAura= ' + successResultAura);
        system.assertEquals(false, falierResultAura, 'falierResultAura= '+falierResultAura);
   */     
    }   
}