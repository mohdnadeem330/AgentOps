@isTest
public class LiveAldarDLPNotificationServiceTest {
    @isTest
    public static void testCustomerNotificationWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerAppWebUser__c = true;
        insert acc;
        
        Test.startTest();
        try { 
            LiveAldarDLPNotificationService.FlowInputParamsWrapper flowParams = new LiveAldarDLPNotificationService.FlowInputParamsWrapper();
            flowParams.accountId = acc.Id;
            flowParams.accountEmail = acc.PersonEmail;
            flowParams.notificationTitle = 'Test Title';
            flowParams.notificationBody = 'Test Body';
            flowParams.notificationARBody = 'Test Body';
            flowParams.type = 'Property Journey';
            flowParams.subType = '';
            flowParams.recordId = 'testRecordId';
            flowParams.importantNotification = 'yes';
            LiveAldarDLPNotificationService.flowNotification(new List<LiveAldarDLPNotificationService.FlowInputParamsWrapper>{flowParams});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}