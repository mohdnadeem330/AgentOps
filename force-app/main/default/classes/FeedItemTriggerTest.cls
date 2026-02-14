@isTest
private class FeedItemTriggerTest {
    @isTest
    static void testFeedItemCreatesComment() {
        // Query existing Queue
        Group g = [SELECT Id FROM Group WHERE DeveloperName = 'North_Baniyas_Queue' AND Type = 'Queue' LIMIT 1];

        // Create Account and Contact
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;

        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test NOC Application',
            OwnerId = g.Id
        );
        insert testCase;

        // Create FeedItem
        FeedItem fi = new FeedItem(
            ParentId = testCase.Id,
            Body = '<p>This is <b>bold</b> and <i>italic</i></p>',
            Type = 'TextPost'
        );
        insert fi;

        // Assert CaseComment was created
        List<CaseComment> comments = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id];
        System.assertEquals(1, comments.size());
        System.assertEquals('This is bold and italic', comments[0].CommentBody);
    }
}