/*
*Created By     : Hardik Vitthani
*Description    : Test class for NewRecordController
*/
@isTest
public class NewRecordControllerTest {
    @isTest
    public static void testGetAccount() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        try {
            NewRecordController.getAccount(acc.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testGetRecordTypeId() {
        try {
            NewRecordController.getRecordTypeId('Account', Constants.PERSON_ACCOUNT_RT);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testOpp() {
        try {
            Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
            insert acc;

            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            opp.EnquiryCategory__c = 'Aldar Employees';
            opp.EnquiryTrigger__c = 'Aldar Hospitality';
            opp.Amount = 50000;
            insert opp;

            NewRecordController.checkOpportunity('');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}