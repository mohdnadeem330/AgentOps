@isTest
public class CustomerCalloutHelperTest {
    /*
    * Purpose : To Test Covrage of Customer Callout Helper
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testCustomerCalloutPerson() {
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        pAcc.OtherERPID__c = '{"temp":"temp"}';
        insert pAcc;

        List<Id> accIds = new List<Id>();
        accIds.add(pAcc.Id);
        try {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, new List<Id>(), '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, accIds, 'Account');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    @isTest
    public static void testCustomerCalloutOrganisation() {
        Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Company', 'TestNumber');
        oAcc.OtherERPID__c = '{"temp":"temp"}';
        insert oAcc;

        List<Id> accIds = new List<Id>();
        accIds.add(oAcc.Id);
        try {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, new List<Id>(), '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, accIds, 'Account');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}