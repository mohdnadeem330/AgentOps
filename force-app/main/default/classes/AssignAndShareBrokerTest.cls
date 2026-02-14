@isTest
private class AssignAndShareBrokerTest {

    @isTest
    static void testAssignAndShare() {
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com'
        );
        insert contact;
        User brokerUser = new User(
            FirstName = 'Test',
            LastName = 'Broker',
            Email = 'testbroker@example.com',
            Username = 'testbroker-' + System.currentTimeMillis() + '@example.com',
            Alias = 'tbroker',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert brokerUser;
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            ContactId = contact.Id 
        );
        insert testCase;
        AssignAndShareBroker.Request req = new AssignAndShareBroker.Request();
        req.recordId = testCase.Id;
        req.userId = brokerUser.Id;

        Test.startTest();
        AssignAndShareBroker.assignAndShare(new List<AssignAndShareBroker.Request>{ req });
        Test.stopTest();
        Case updatedCase = [SELECT Id, Assigned_To__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(brokerUser.Id, updatedCase.Assigned_To__c);

        List<CaseShare> shares = [SELECT Id FROM CaseShare WHERE CaseId = :testCase.Id AND UserOrGroupId = :brokerUser.Id];
        System.assertEquals(1, shares.size());
    }
}