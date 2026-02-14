@isTest
public class AddressVerificationControllerTest {
    /*
    * Purpose : To Test Covrage of Account Verification
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testAddressVerification() {
        // Account acc = new Account();
        // User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // System.runAs(thisUser) {
            // EmailTemplate emailTemplate = TestObjectsFactory.getEmailTemplate('CustomerAddressVerification', 'custom');
            // insert emailTemplate;

            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
        // }

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<Id> soIds = new List<Id>();
        soIds.add(salesOrder.Id);
        try {
            AddressVerificationController.VerifyAddress(soIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}