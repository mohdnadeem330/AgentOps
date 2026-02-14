/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchToMonthlySalesTargetService
*/
@isTest
public class BatchToMonthlySalesTargetServiceTest {
    @isTest
    public static void testInventoryMonthlySalesTarget() {
        getData('Inventory');

        try {
            database.executeBatch(new BatchToMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Monthly Sales Target Service Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('TTest Monthly Sales Target Service Batch', '0 0 23 * * ?', new BatchToMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testLaunchMonthlySalesTarget() {
        getData('Launch');

        try {
            database.executeBatch(new BatchToMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Monthly Sales Target Service Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('Test Monthly Sales Target Service Batch', '0 0 23 * * ?', new BatchToMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }

    public static void getData(String inventoryLaunch) {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        acc.PersonEmail = 'test@aldar.com.invalid';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        salesOrder.BrokerManager__c = UserInfo.getUserId();
        salesOrder.InventoryLaunch__c = inventoryLaunch;
        salesOrder.BookingDate__c = date.today().addDays(-3);
        salesOrder.SalesApprovedDate__c = date.today().addDays(-3);
        salesOrder.NetAmount__c = 50000;
        salesOrder.Status__c = Constants.SO_STATUS_SOLD;
        insert salesOrder;

        User usr = [SELECT Id FROM User WHERE Profile.Name =: Constants.SALES_MANAGER AND IsActive = true LIMIT 1];

        MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, Constants.USER_TEAM_DXB);
        insert monthlySalesTarget;
        MonthlySalesTarget__c monthlySalesTarget2 = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, Constants.USER_TEAM_DXB);
        monthlySalesTarget2.AchievedAmount__c = 50000;
        insert monthlySalesTarget2;
    }
}