@isTest(SeeAllData=true)
private  class DMCustomCommentFeederControllerTest {
    // Test method for createFeedItemRec
    @isTest
    static void testCreateFeedItemRec() {
        // Insert test data
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC',
            Status ='New',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;
        
        FeedItem feedItem = new FeedItem(
            ParentId = testCase.Id,
            Body = 'Test Body'
        );
        insert feedItem;
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser1001@test.com'
        );
        insert testUser;
        
        // Call the method to be tested
        Test.startTest();
        DMCustomCommentFeederController.createFeedItemRec(feedItem, testUser.Id,null);
        DMCustomCommentFeederController.createFeedForAldar(feedItem, testUser.Id);
        Test.stopTest();
    }
    
    // Test method for sendEmail
    @isTest
    static void testSendEmail() {
        // Insert test data if needed
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC',
            Status ='New',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;
        
        FeedItem feedItem = new FeedItem(
            ParentId = testCase.Id,
            Body = 'Test Body'
        );
        insert feedItem;
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser1001@test.com'
        );
        insert testUser;
        
        // Call the method to be tested
        Test.startTest();
        DMCustomCommentFeederController.sendEmail(UserInfo.getUserId(), feedItem);
        Test.stopTest();
        
    }
    
    // Test method for getFeedItemList
    @isTest
    static void testGetFeedItemList() {
        // Insert test data
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC',
            Status ='New',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;
        
        FeedItem feedItem1 = new FeedItem(
            ParentId = testCase.Id,
            Type = 'TextPost',
            Body = 'Test Feed Item 1'
        );
        insert feedItem1;
        
        FeedItem feedItem2 = new FeedItem(
            ParentId = testCase.Id,
            Type = 'CreateRecordEvent',
            Body = 'Test Feed Item 2'
        );
        insert feedItem2;
        
        // Call the method to be tested
        Test.startTest();
        List<FeedItem> result = DMCustomCommentFeederController.getFeedItemList(testCase.Id);
        Test.stopTest();
        
    }
}