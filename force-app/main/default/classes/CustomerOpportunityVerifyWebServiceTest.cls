@isTest
public class CustomerOpportunityVerifyWebServiceTest {

    @isTest
    public static void testCustomerOpportunityVerifyWebService() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'test@aldar.com';
        insert acc;
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c = acc.Id;
        cp.Status__c ='Link Sent';
        cp.Category__c = 'Booking';
        cp.Active__c = true;
        insert cp;

        Document__c docRecord = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert docRecord;

        ContentVersion content = TestObjectsFactory.getContentVersion();
        insert content;

        ContentDocumentLink contentlink = TestObjectsFactory.insertContentDocumentLink(docRecord.Id, content.Id);

        Document__c docRecord1 = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC);
        insert docRecord1;

        Opportunity oppRec = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert oppRec;

        Appointment__c appRecord = new Appointment__c();
        appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        appRecord.Date__c = date.today();
        appRecord.Slot__c = '08:00 - 09:00';
        appRecord.AppointmentId__c = '123';
        appRecord.Broker__c = UserInfo.getUserId();
        appRecord.StartTime__c = Time.newInstance(18, 30, 2, 20);
        appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
        appRecord.EncryptedRecordId__c = 'test123';
        appRecord.Opportunity__c = oppRec.Id;
        appRecord.Email__c = acc.PersonEmail;
        insert appRecord;

        TestObjectsFactory.initializeRestContext(null, '/query/opportunityverify');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerOpportunityVerifyWebService.doPost(appRecord.EncryptedRecordId__c, appRecord.Email__c);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerOpportunityVerifyWebService2() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'test@aldar.com';
        insert acc;
        
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c = acc.Id;
        cp.Status__c ='Link Sent';
        cp.Category__c = 'Booking';
        cp.Active__c = true;
        insert cp;

        Opportunity oppRec = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert oppRec;

        Appointment__c appRecord = new Appointment__c();
        appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        appRecord.Date__c = date.today();
        appRecord.Slot__c = '08:00 - 09:00';
        appRecord.AppointmentId__c = '123';
        appRecord.Broker__c = UserInfo.getUserId();
        appRecord.StartTime__c = Time.newInstance(18, 30, 2, 20);
        appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
        appRecord.EncryptedRecordId__c = 'test123';
        appRecord.Opportunity__c = oppRec.Id;
        appRecord.Email__c = acc.PersonEmail;
        insert appRecord;

        TestObjectsFactory.initializeRestContext(null, '/query/opportunityverify');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            List<Document__c> deleteDocList = [SELECT Id, Account__c FROM Document__c WHERE Account__c =: acc.Id];
            if (!deleteDocList.isEmpty()) {
                delete deleteDocList;
            }

            CustomerOpportunityVerifyWebService.doPost(cp.Id, 'test@aldar.com');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerOpportunityVerifyWebService3() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'test@aldar.com';
        insert acc;

        Opportunity oppRec = TestObjectsFactory.getOpportunityRecord(acc.Id);
        oppRec.FastTrackedOpportunity__c = true;
        insert oppRec;

        Appointment__c appRecord = new Appointment__c();
        appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        appRecord.Date__c = date.today();
        appRecord.Slot__c = '08:00 - 09:00';
        appRecord.AppointmentId__c = '123';
        appRecord.Broker__c = UserInfo.getUserId();
        appRecord.StartTime__c = Time.newInstance(18, 30, 2, 20);
        appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
        appRecord.EncryptedRecordId__c = 'test123';
        appRecord.Opportunity__c = oppRec.Id;
        appRecord.Email__c = acc.PersonEmail;
        insert appRecord;

        TestObjectsFactory.initializeRestContext(null, '/query/opportunityverify');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerOpportunityVerifyWebService.doPost(appRecord.EncryptedRecordId__c, appRecord.Email__c);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
     @isTest
    public static void testCustomerOpportunityVerifyWebService4() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'test@aldar.com';
        acc.EncryptedRecordId__c = 'test123';
        acc.FastTrackedAccount__c = true;
        insert acc;
        
        TestObjectsFactory.initializeRestContext(null, '/query/opportunityverify');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerOpportunityVerifyWebService.doPost(acc.EncryptedRecordId__c, acc.PersonEmail);
            CustomerOpportunityVerifyWebService.doPost('test_12_34', acc.PersonEmail);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerOpportunityVerifyWebService5() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{}'));

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'tes1t@aldar.com';
        acc.EncryptedRecordId__c = 'test1234';
        acc.FastTrackedAccount__c = false;
        insert acc;
        
        TestObjectsFactory.initializeRestContext(null, '/query/opportunityverify');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerOpportunityVerifyWebService.doPost(acc.EncryptedRecordId__c, acc.PersonEmail);
            CustomerOpportunityVerifyWebService.doPost('test_12_34', acc.PersonEmail);
            CustomerOpportunityVerifyWebService.doPost(null, acc.PersonEmail);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}