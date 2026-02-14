@isTest
private class EmailValidationTest {
    @isTest static  void emailValidationCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        boolean successResult = EmailValidation.validateEmail(new List<String>{'ali.athamneh@pwc.com'})[0];
        boolean successResultAura= EmailValidation.getValidateEmailWithAura('ali.athamneh@pwc.com');

        // Fail Mock
        mock.setStaticResource('GetEmailValidationFail');
        Test.setMock(HttpCalloutMock.class, mock);


        boolean falierResult = EmailValidation.validateEmail(new List<String>{'ali.athamneh'})[0];
        boolean falierResultAura = EmailValidation.getValidateEmailWithAura('ali.athamneh');

   /*     system.assertEquals(true, successResult, 'successResult= ' + successResult);
        system.assertEquals(false, falierResult, 'falierResult= '+falierResult);

        system.assertEquals(true, successResultAura, 'successResultAura= ' + successResultAura);
        system.assertEquals(false, falierResultAura, 'falierResultAura= '+falierResultAura);
     */   
    }   
}