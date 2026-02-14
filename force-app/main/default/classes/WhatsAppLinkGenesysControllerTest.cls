@isTest
public class WhatsAppLinkGenesysControllerTest {
    
    @isTest static  void sendWhatsAppLinkTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        insert acc;  
        test.startTest();
        WhatsAppLinkGenesysController.sendfastTrackLink(new List<Id>{acc.Id});
        System.enqueueJob(new SendfastTrackWhatsappLinkQueueable('www.google.com',acc.Id));
        Test.stopTest();
    }

}