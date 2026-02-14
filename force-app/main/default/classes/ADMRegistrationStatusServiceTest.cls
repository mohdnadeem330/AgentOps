@isTest
private class ADMRegistrationStatusServiceTest {
  
    @isTest
    public static void callMethod (){
        Test.startTest();

        ADMRegistrationStatusService.updateStatus('1234', 'Approved');

        Test.stopTest();
    }
}