@isTest(SeeAllData=false)
public class ValidateEmailMobileNoWebserviceTest {
    @isTest static void setupMethod() {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        TestObjectsFactory.initializeRestContext(null, '/validate/EmailOrMobileNumber');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);

        Test.startTest();
        
        ValidateEmailMobileNoWebservice.doPostMethod('test@pwc.com','7030181809');
        ValidateEmailMobileNoWebservice.doPostMethod('test@pwc.com','');
        ValidateEmailMobileNoWebservice.doPostMethod('','7030181809');
        
        Test.stopTest();
    }
}