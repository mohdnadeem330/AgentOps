@isTest(SeeAllData=false)
public class SalesOrderServiceTest {
    @isTest static void setupData() {

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;

        Account orgAcc1 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc1;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opportunityRecord;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;

        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAcc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.ProjectBudget__c = projectBudget.Id;
        insert salesOrder;

        SalesOrderCancellation__c salesOrderCancellation = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder.Id, unit.Id);
        insert salesOrderCancellation;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(orgAcc1.Id,20,'Spouse of');
        jointOwner.SalesOrder__c = salesOrder.Id;
        insert jointOwner;

        Set<Id> accountId = new Set<Id>();
        accountId.add(orgAcc.Id);

        Set<Id> opptyId = new Set<Id>();
        opptyId.add(opportunityRecord.Id);

        Set<Id> soId = new Set<Id>();
        soId.add(salesOrder.Id);

        Set<String> soStrigId = new Set<String>();
        soStrigId.add(salesOrder.Id);

        Set<Id> projectBudgetId = new Set<Id>();
        projectBudgetId.add(projectBudget.Id);

        List<Id> soIdList = new List<Id>();
        soIdList.add(salesOrder.Id);
        String soIdsStr = String.join(soIdList, '\',\'');
        String whrClause = ' Id IN (\'' + soIdsStr + '\') ';

        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        salesOrderList.add(salesOrder);

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('Status__c',Constants.SALES_STATUS);

        Map<String,String> mapFieldApiFieldValues1 = new Map<String,String>();

        

        Test.startTest();
		List<SalesOrder__c> getSalesOrderDetailsWithWhereClause = SalesOrderService.getSalesOrderDetailsWithWhereClause(whrClause);
        List<SalesOrder__c> soByAccountId = SalesOrderService.getSalesOrderByAccountId(accountId);
        List<SalesOrder__c> soBySORecord = SalesOrderService.getSalesOrderRec(salesOrder.Id);
        Map<Id,List<SalesOrder__c>> accountOpportunityUnitMap =  SalesOrderService.getAccountOpportunityUnitMap(accountId);
        Map<Id,List<SalesOrder__c>> opportunitySalesOrderMap =  SalesOrderService.getOpportunitySalesOrderMap(opptyId);

        List<AggregateResult> getSalesOrdersBookedToday = SalesOrderService.getSalesOrdersBookedToday(projectBudgetId);
        List<AggregateResult> getSalesOrdersCancelledToday = SalesOrderService.getSalesOrdersCancelledToday(projectBudgetId);

        Set<Id> salesOrdersAccountIds = SalesOrderService.getSalesOrdersAccountIds(salesOrder.Id);
        Set<Id> allSalesOrdersAccountIds = SalesOrderService.getAllSalesOrdersAccountIds(soId);
        List<SalesOrder__c> salesOrderForManager = SalesOrderService.getSalesOrderForManager(mapFieldApiFieldValues);
        List<SalesOrder__c> salesOrderForManager1 = SalesOrderService.getSalesOrderForManager(mapFieldApiFieldValues1);

        List<SalesOrder__c> fetchSalesOrderByAccountId = SalesOrderService.fetchSalesOrderByAccountId(orgAcc.Id);
        List<SalesOrder__c> fetchSalesOrderForAPIByUser = SalesOrderService.fetchSalesOrderForAPIByUser(userInfo.getUserId());
        List<SalesOrder__c> queryAllFieldsWithExtraFields = SalesOrderService.queryAllFieldsWithExtraFields(soIdList);
        SalesOrder__c getAccountWithJointOwners = SalesOrderService.getAccountWithJointOwners(salesOrder.Id);

        SalesOrderService.newOpportunityUnitRecord(salesOrderList);
        Boolean cancelSalesOrderReservation = SalesOrderService.cancelSalesOrderReservation(soStrigId);
        List<SalesOrder__c> getOpportunityUnitByAccountId = SalesOrderService.getOpportunityUnitByAccountId(accountId);
        List<SalesOrder__c> getSalesOrderByOpportunityId = SalesOrderService.getSalesOrderByOpportunityId(opportunityRecord.Id);

        List<SalesOrder__c> getSalesOrderByOpportunityIdSet = SalesOrderService.getSalesOrderByOpportunityIdSet(opptyId);
        SalesOrder__c getSalesOrderByUnitId = SalesOrderService.getSalesOrderByUnitId(unit.Id);
        List<SalesOrder__c> getSalesOrdersByUnitIds = SalesOrderService.getSalesOrdersByUnitIds(new List<id>{unit.Id});

        List<SalesOrderCancellation__c> getSalesOrderCancellation = SalesOrderService.getSalesOrderCancellation(salesOrder.Id);
        set<string> getMandatoryDocStatus = SalesOrderService.getMandatoryDocsStatus(salesOrder);
        SalesOrderService.getAllActiveDirectDebitRequests(salesOrder.Id);
		SalesOrderService.getMandatoryDocs(opportunityRecord.Id);
        Test.stopTest();
    }
}