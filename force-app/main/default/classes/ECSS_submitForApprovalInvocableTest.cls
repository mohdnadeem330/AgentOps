@isTest
public class ECSS_submitForApprovalInvocableTest {

    @testSetup
    static void setupTestData() {
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        User approver = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        if (approver == null) {
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            approver = new User(
                FirstName = 'Test',
                LastName = 'Approver',
                Alias = 'testapprover',
                Email = 'test.approver@example.com',
                Username = 'test.approver@example.com.' + System.currentTimeMillis(),
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            );
            insert approver;
        }
    }

    @isTest
    static void testSubmitForApproval() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        User approver = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        ECSS_submitForApprovalInvocable.invocableWrapper input = new ECSS_submitForApprovalInvocable.invocableWrapper();
        input.objID = testOpportunity.Id;
        input.ApproversIds = new List<Id>{approver.Id};

        // Invoke the method
        Test.startTest();
        ECSS_submitForApprovalInvocable.submitForApproval(new List<ECSS_submitForApprovalInvocable.invocableWrapper>{input});
        Test.stopTest();

       
    }
}