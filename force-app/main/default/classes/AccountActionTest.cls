@isTest
public class AccountActionTest {
    @isTest
    static void testCreateCase() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Test.startTest();
        AccountAction.createCase(new List<Id>{acc.Id});
        Test.stopTest();

        Case[] cases = [SELECT Id FROM Case WHERE AccountId = :acc.Id];
        System.assertNotEquals(0, cases.size(), 'Case should have been created');
    }
}