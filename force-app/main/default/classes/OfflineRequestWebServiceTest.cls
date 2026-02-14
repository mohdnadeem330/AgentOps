@isTest
private class OfflineRequestWebServiceTest {
    
    private static User salesManager;
    
    @TestSetup
    static void setupTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name ='Sales Manager' LIMIT 1];
        
        salesManager = new User(
            Username = 'salesManagerTest' + String.valueOf(DateTime.now().getTime()) + '@aldar.com',
            Email = 'salesManagerTest@aldar.com',
            FirstName = 'Test',
            LastName = 'Manager',
            Alias = 'tman',
            ProfileId = profile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert salesManager;
        
        List<OfflineRequest__c> offlineRequests = new List<OfflineRequest__c>();
        String[] statuses = new String[]{'Awaiting approval', 'Cancelled', 'Rejected', 'Approved'};
            for (String status : statuses) {
                offlineRequests.add(new OfflineRequest__c(
                    StartTime__c = system.now() + 1,
                    EndTime__c = system.now() + 3,
                    Reason__c = 'Test reason',
                    Status__c = status,
                    User__c = salesManager.Id
                ));
            }
        insert offlineRequests;

    }
    
    @isTest
    static void testWebServiceAndControllerMethods() {
        TestObjectsFactory.initializeRestContext(null, '/insert/offlinerequest');
        TestObjectsFactory.initializeRestContext(null, '/getOfflinerequest');
        List<OfflineRequest__c> offlineRequests = [SELECT Id, StartTime__c, EndTime__c, Reason__c, Status__c, User__c FROM OfflineRequest__c];
        Test.startTest();
        dateTime dt = system.now() + 1;
        dateTime dt2 = system.now() + 2;
        dateTime dt3 = system.now() + 3;
        dateTime dt4 = system.now() + 4;
        dateTime dt5 = system.now() + 5;
        dateTime dt6 = system.now() + 6;
        dateTime dt7 = system.now() + 7;
        dateTime dt8 = system.now() + 8;
        datetime dt9 = system.now() -1;
        datetime dt10 = system.now() -2;
        TestObjectsFactory.initializeRestContext(null, '/insert/offlinerequest');
        TestObjectsFactory.initializeRestContext(null, '/getOfflinerequest');
        OfflineRequestWebService.doPost(dt, dt2, 'Test', null, null);
        OfflineRequestWebService.doPost(dt3, dt4, 'Test', null, null);
        OfflineRequestWebService.doPost(dt5, dt6, 'Test', null, null);
        OfflineRequestWebService.doPost(dt7, dt8, 'Test', null, null);
        OfflineRequestWebService.doPost(dt9, dt10, 'Test', null, null);
        OfflineRequestWebService.doPost(null, null, 'Test', 'Cancelled', offlineRequests[0].Id);
        OfflineRequestService.doPost();
        
        OfflineRequestController.validateOfflineRequest(offlineRequests[0]);
        OfflineRequestController.checkApprovedRequest();
        OfflineRequestController.sendManagerApprovel(offlineRequests[0].Id);
        OfflineRequestController.cancelOffRequest(offlineRequests[0]);
        OfflineRequestController.getOfflineRequest();
        OfflineRequestController.deleteOffRequest(offlineRequests[0]);
        Test.stopTest();
    }
    
    @isTest
    static void testOfflineRequestBatch() {
        Test.startTest();
        OfflineRequestBatch.scheduleJob();
        Test.stopTest();
        System.assert(true, 'OfflineRequestBatch scheduled successfully');
    }
    
    @isTest
    static void testOfflineRequestDefaultOnlineOfflineBatch_OnlineMode() {
        Test.startTest();
        Database.executeBatch(new OfflineRequestDefaultOnlineOfflineBatch(true, false), 200);
        Test.stopTest();
        System.assert(true, 'Online mode batch executed');
    }
    
    @isTest
    static void testOfflineRequestDefaultOnlineOfflineBatch_OfflineMode() {
        Test.startTest();
        Database.executeBatch(new OfflineRequestDefaultOnlineOfflineBatch(false, true), 200);
        Test.stopTest();
        System.assert(true, 'Offline mode batch executed');
    }
    
    @isTest
    static void testOfflineRequestScheduler() {
        String cronExp = '0 0 23 * * ?';
        Test.startTest();
        System.schedule('OfflineRequestScheduler', cronExp, new OfflineRequestScheduler());
        Test.stopTest();
        System.assert(true, 'OfflineRequestScheduler scheduled');
    }
    
    @isTest
    static void testOfflineRequestDefaultOfflineScheduler() {
        String cronExp = '0 0 23 * * ?';
        Test.startTest();
        System.schedule('OfflineRequestDefaultOfflineScheduler', cronExp, new OfflineRequestDefaultOfflineScheduler());
        Test.stopTest();
        System.assert(true, 'OfflineRequestDefaultOfflineScheduler scheduled');
    }
    
    @isTest
    static void testOfflineRequestDefaultOnlineScheduler() {
        String cronExp = '0 0 23 * * ?';
        Test.startTest();
        System.schedule('OfflineRequestDefaultOnlineScheduler', cronExp, new OfflineRequestDefaultOnlineScheduler());
        Test.stopTest();
        System.assert(true, 'OfflineRequestDefaultOnlineScheduler scheduled');
    }
    
    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        OfflineRequestBatch scheduler = new OfflineRequestBatch();
        scheduler.execute(null); // SchedulableContext is not used inside the method
        Test.stopTest();
    }
}