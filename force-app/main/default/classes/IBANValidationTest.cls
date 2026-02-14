@isTest
private class IBANValidationTest {



    @isTest static  void validationCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetIBANValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        String iban = 'AE070331234567890123456';

        Test.startTest();
        IBANValidation.getValidateIbanWithAura(iban);
        Test.stopTest();

        boolean successResult = IBANValidation.getValidateIbanWithAura(iban);
        
        // Fail Mock
        iban = 'AE1222112';
        mock.setStaticResource('GetIBANValidationFail');
        Test.setMock(HttpCalloutMock.class, mock);

        IBANValidation.getValidateIbanWithAura(iban);

        boolean falierResult = IBANValidation.getValidateIbanWithAura(iban);

        system.assertEquals(true, successResult, 'successResult= ' + successResult);
        system.assertEquals(false, falierResult, 'falierResult= '+falierResult);

    }
}