/**
* BrokerManagerCommissionCalBatchTest
*
* Test class for BrokerManagerCommissionCalculationBatch
*/
@isTest
public class BrokerManagerCommissionCalBatchTest {
	@isTest
    Public static void commissionPayoutCalculationInventory(){
        	getData('Inventory');
        database.executeBatch(new BrokerManagerCommissionCalculationBatch());
    }
    public static void getData(String inventoryLaunch) {
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
        Contact objContact = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        acc.PersonEmail = 'test@aldar.com.invalid';
        acc.ResidentStatus__pc = 'Resident';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        opp.SaleType__c = 'New Sale';
        opp.AgentType__c = Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT;
        opp.BrokerAgencyAccount__c = orgAcc.Id;
        opp.BrokerAgentContact__c = objContact.Id;
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
        salesOrder.SoldDate__c = Date.newInstance(date.today().year(), date.today().month()-1, 10);
        salesOrder.Status__c = Constants.SO_STATUS_SOLD;
        insert salesOrder;
		PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlan;
        
        list<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallment(paymentPlan.Id);
        insert paymentInstallmentList;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.getInstallmentLines(salesOrder.id, paymentPlan.Id, paymentInstallmentList);
        insert  installmentLineList;
        CommissionLineItem__c objCommissionLineItem = TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
		objCommissionLineItem.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;  
        update objCommissionLineItem;
        
        MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(UserInfo.getUserId(), Constants.USER_TEAM_DXB);
        monthlySalesTarget.TargetMonth__c = String.valueOf(date.today().month()-1);
        monthlySalesTarget.AcceleratorPercentage__c = 0.2;
        monthlySalesTarget.KPI1__c  = 100;
        monthlySalesTarget.KPI2__c  = 100;
        monthlySalesTarget.AchievedAmount__c  = 200000;
        monthlySalesTarget.TargetAmount__c  = 100000;
        monthlySalesTarget.TargetYear__c = String.valueOf(date.today().year());
        insert monthlySalesTarget;
        MonthlySalesTarget__c monthlySalesTarget2 = TestObjectsFactory.getMonthlySalesTargetRecord(UserInfo.getUserId(), Constants.USER_TEAM_DXB);
        
        monthlySalesTarget2.TargetMonth__c = String.valueOf(date.today().month()-1);
        monthlySalesTarget2.AcceleratorPercentage__c = 0.2;
        monthlySalesTarget2.KPI1__c  = 100;
        monthlySalesTarget2.KPI2__c  = 80;
        monthlySalesTarget2.AchievedAmount__c  = 150000;
        monthlySalesTarget2.TargetAmount__c  = 100000;
        monthlySalesTarget2.TargetYear__c = String.valueOf(date.today().year());
        insert monthlySalesTarget2;
    }
}