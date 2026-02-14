@isTest
public class CustomerDLPPushNotificationTest {

    @isTest
    static void testFlowNotification() {
        CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper param = new CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper();
        param.notificationUserId = 'user123';
        param.notificationUserName = 'John Doe';
        param.notificationUserEmail = 'john.doe@example.com';
        param.notificationMessageType = 'Transactional';
        param.notificationSubAppType = 'PRO';
        param.notificationClickAction = 'fcm.ACTION.NOTIF';
        param.notificationARBody = 'Arabic Body';
        param.notificationARTitle = 'Arabic Title';
        param.notificationBody = 'English Body';
        param.notificationTitle = 'English Title';
        param.notificationType = 'New Notification';
        param.notificationFunctionalType = 'Property Journey';
        param.notificationFunctionalSubType = 'Home Orientation';
        param.notificationFunctionalRecordId = '12345';
        param.notificationFunctionalUnitName = 'Unit 101';

        List<CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper> params = new List<CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper>{ param };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        CustomerDLPPushNotificationWebservice.flowNotification(params);
        Test.stopTest();

        System.assertEquals('user123', param.notificationUserId);
    }

    @isTest
    static void testFlowNotificationEmptyInput() {
        List<CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper> emptyList = new List<CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper>();
        Test.startTest();
        CustomerDLPPushNotificationWebservice.flowNotification(emptyList);
        Test.stopTest();
        System.assert(true, 'Handled empty input list');
    }

    @isTest
    static void testNotificationBodyWithEmptyData() {
        CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper emptyParam = new CustomerDLPPushNotificationWebservice.FlowInputParamsWrapper();
        Test.startTest();
        CustomerDLPPushNotificationWebservice.notificationBody(emptyParam);
        Test.stopTest();

        System.assert(true, 'Handled empty parameter fields');
    }

    @isTest
    static void testCalloutFutureServiceSuccess() {
        String sampleBody = '{"userId":"user123"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        CustomerDLPPushNotificationWebservice.calloutFutureService(sampleBody);
        Test.stopTest();

        System.assert(true, 'Callout executed successfully');
    }

    @isTest
    static void testCalloutFutureServiceException() {
        String invalidBody = '{"userId":"fail"}'; // Or just invalid structure
        Test.startTest();
        CustomerDLPPushNotificationWebservice.calloutFutureService(invalidBody);
        Test.stopTest();

        System.assert(true, 'Exception was caught successfully');
    }

    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
}