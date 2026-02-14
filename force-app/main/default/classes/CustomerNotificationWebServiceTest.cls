@isTest
public class CustomerNotificationWebServiceTest {
    
    
     @isTest
    public static void testCustomerNotificationWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerAppWebUser__c = true;
        insert acc;
        
        Test.startTest();
        try {
            CustomerNotificationWebService.FlowInputParamsWrapper flowParams = new CustomerNotificationWebService.FlowInputParamsWrapper();
            flowParams.accountId = acc.Id;
            flowParams.accountEmail = acc.PersonEmail;
            flowParams.notificationTitle = 'Test Title';
            flowParams.notificationBody = 'Test Body';
            flowParams.notificationARBody = 'Test Body';
            flowParams.type = 'Property Journey';
            flowParams.subType = '';
            flowParams.recordId = 'testRecordId';
            flowParams.importantNotification = 'yes';
            CustomerNotificationWebService.flowNotification(new List<CustomerNotificationWebService.FlowInputParamsWrapper>{flowParams});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
	
    @isTest
    public static void testCustomerPushNotificationWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerAppWebUser__c = true;
        insert acc;
        
        Test.startTest();
        try {
            CustomerPushNotificationWebservice.FlowInputParamsWrapper flowParams = new CustomerPushNotificationWebservice.FlowInputParamsWrapper();
            
            flowParams.notificationUserId = acc.PersonEmail;
            flowParams.notificationUserName = acc.Name;
            flowParams.notificationUserEmail = acc.PersonEmail;
            flowParams.notificationMessageType = 'transactional';
            flowParams.notificationSubAppType = 'PRO';
            flowParams.notificationClickAction = 'fcm.ACTION.NOTIF';
            flowParams.notificationARBody = 'Test Arabic Body';
            flowParams.notificationARTitle = 'Test Arabic Title';
            flowParams.notificationBody = 'Test Body';
            flowParams.notificationTitle = 'Test Title';
            flowParams.notificationType = 'NOTIFICATION';
            flowParams.notificationFunctionalType = 'DIGITAL_SALES';
            flowParams.notificationFunctionalSubType = 'DIGITAL_SALES_NOTIFICATION';
            flowParams.notificationFunctionalRecordId = 'yes';
            flowParams.notificationFunctionalUnitName = 'MAYAN-B1-23-05';
            
            
            CustomerPushNotificationWebservice.flowNotification(new List<CustomerPushNotificationWebservice.FlowInputParamsWrapper>{flowParams});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerEnqueueNotificationWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerAppWebUser__c = true;
        insert acc;
        
        Test.startTest();
        try {
            CustomerPushNotificationWebservice.FlowInputParamsWrapper flowParams = new CustomerPushNotificationWebservice.FlowInputParamsWrapper();
            
            flowParams.notificationUserId = acc.PersonEmail;
            flowParams.notificationUserName = acc.Name;
            flowParams.notificationUserEmail = acc.PersonEmail;
            flowParams.notificationMessageType = 'transactional';
            flowParams.notificationSubAppType = 'PRO';
            flowParams.notificationClickAction = 'fcm.ACTION.NOTIF';
            flowParams.notificationARBody = 'Test Arabic Body';
            flowParams.notificationARTitle = 'Test Arabic Title';
            flowParams.notificationBody = 'Test Body';
            flowParams.notificationTitle = 'Test Title';
            flowParams.notificationType = 'NOTIFICATION';
            flowParams.notificationFunctionalType = 'DIGITAL_SALES';
            flowParams.notificationFunctionalSubType = 'DIGITAL_SALES_NOTIFICATION';
            flowParams.notificationFunctionalRecordId = 'yes';
            flowParams.notificationFunctionalUnitName = 'MAYAN-B1-23-05';
            
            //CustomerNotificationWebService.enqueueNotification(new List<CustomerNotificationWebService.FlowInputParamsWrapper>{flowParams});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}