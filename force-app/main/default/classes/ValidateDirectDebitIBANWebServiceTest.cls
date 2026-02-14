@isTest
public class ValidateDirectDebitIBANWebServiceTest {
    
    @isTest
    public static void doPostTest1() {
        Test.startTest();
        String ibanResponseBody = '{"Data":{"IBANAccountNumber":"AE680230000001000000002","IBANAccountTitle": "AHM*** MUST*** HAS*** AHL*** "}}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(ibanResponseBody));
        
        TestObjectsFactory.initializeRestContext(null, '/validate/directDebit');
        ValidateDirectDebitIBANWebService.doPost('John Doe','AE680230000001000000002');
        Test.stopTest();        
    }
    
    @isTest
    public static void doPostTest2() {
        Test.startTest();
        String ibanResponseBody = '{}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(ibanResponseBody));
        
        TestObjectsFactory.initializeRestContext(null, '/validate/directDebit');
        ValidateDirectDebitIBANWebService.doPost('John Doe','AE680230000001000000002');
        Test.stopTest();        
    }
    
    @isTest
    public static void doPostTest3() {
        Test.startTest();
        /*String ibanResponseBody = '{"Data":{"IBANAccountNumber":"AE680230000001000000002","IBANAccountTitle": "AHM*** MUST*** HAS*** AHL*** "}}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(ibanResponseBody));*/
        
        TestObjectsFactory.initializeRestContext(null, '/validate/directDebit');
        ValidateDirectDebitIBANWebService.doPost('John Doe','AE680230000001000000002');
        Test.stopTest();        
    }
    
    @isTest
    public static void doPostTest4() {
        Test.startTest();
        /*String ibanResponseBody = '{"Data":{"IBANAccountNumber":"AE680230000001000000002","IBANAccountTitle": "AHM*** MUST*** HAS*** AHL*** "}}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(ibanResponseBody));*/
        
        TestObjectsFactory.initializeRestContext(null, '/validate/directDebit');
        ValidateDirectDebitIBANWebService.doPost('John Doe','AE680230000001000000ASDF');
        Test.stopTest();        
    }    
    
}