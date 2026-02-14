@isTest
private class SmsNotificationAPITest {
    @isTest static  void sendSmsCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.OwnerId = UserInfo.getUserId();

        SmsNotificationAPI.SmsRequest sms = new SmsNotificationAPI.SmsRequest();
        sms.destination = '971547934361';
        sms.smsBody = 'SMS Body Test';
        sms.record = leadRec;
        database.insert(sms.record,false);

        Test.startTest();
        SmsNotificationAPI.sendSmsNotification(new List<SmsNotificationAPI.SmsRequest>{sms});
        futureCallout(sms.smsBody, sms.destination, leadRec.Id, leadRec.OwnerId);

        Test.stopTest();

        sms.destination = '962787120342';
        // Fail Mock
        mock.setStaticResource('GetSMSNotificationFail');
        Test.setMock(HttpCalloutMock.class, mock);

        SmsNotificationAPI.sendSmsNotification(new List<SmsNotificationAPI.SmsRequest>{sms});  
        futureCallout(sms.smsBody, sms.destination, leadRec.Id, leadRec.OwnerId);
   
    }   

    @future(callout = true)
    public static void futureCallout(string smsText,String destination, String recordId, String ownerId){
        APISetting__mdt  smsAPI = Utilities.getServiceDetails(Constants.SMS);

        String smsEndPointURL = smsAPI.SandboxURL__c ;
        
        Organization org = Utilities.getOrganizationDetails();

        if(!org.IsSandbox){
            smsEndPointURL = smsAPI.ProductionURL__c ; 
        }
        SmsNotificationAPI.nonFutureCallout(smsText, destination, recordId, ownerId, smsEndPointURL, smsAPI.username__c, smsAPI.apiId__c, smsAPI.source__c, smsAPI.Method__c);
    }
}