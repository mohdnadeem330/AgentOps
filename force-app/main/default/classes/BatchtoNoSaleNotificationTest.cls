/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchtoNoSaleNotification
*/
@isTest
public class BatchtoNoSaleNotificationTest {
    @isTest
    public static void testBatchToNoSaleNotification() {
        Test.startTest();

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        User newUser = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;

        System.runAs(newUser) {
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;

            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            opp.EnquiryCategory__c = 'Aldar Employees';
            opp.EnquiryTrigger__c = 'Aldar Hospitality';
            opp.SalesManager__c = newUser.Id;
            insert opp;
            
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            insert unit;

            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unit.Id;
            salesOrder.BookingDate__c = Date.today().addDays(-7);
            salesOrder.SalesManager__c = newUser.Id;
            insert salesOrder;
        }
        
        try {
            database.executeBatch(new BatchtoNoSaleNotification(newUser.Id), 200);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}