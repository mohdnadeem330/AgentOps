/*
*Created By     : Hardik Vitthani
*Description    : Test class for AccountRelationshipService
*/
@isTest
public class AccountRelationshipServiceTest {

    static  Account acc1 ;

    @isTest
    public static void testAccountRelationshipType() {
        acc1 = TestObjectsFactory.getPersonAccountRecord();
        insert acc1;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        AccountRelationship__c accountRelation = TestObjectsFactory.getAccountRelationship(acc1.Id, acc2.Id, 'Friend Of');
        insert accountRelation;

        try {
            Test.startTest();
            List<AccountRelationship__c> accountRelationList = AccountRelationshipService.getAccountRelationshipType(new Set<Id>{accountRelation.Id});
            System.assertEquals(accountRelation.Id, accountRelationList[0].Id);
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testAccountRelationshipFromAccountId() {
        acc1 = TestObjectsFactory.getPersonAccountRecord();
        insert acc1;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        AccountRelationship__c accountRelation = TestObjectsFactory.getAccountRelationship(acc1.Id, acc2.Id, 'Friend Of');
        insert accountRelation;

        List<AccountRelationship__c> accountRelationList = AccountRelationshipService.getAccountRelationshipFromAccountId(acc1.Id);
        System.assertEquals(accountRelation.Id, accountRelationList[0].Id);
    }
}