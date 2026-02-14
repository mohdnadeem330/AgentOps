@isTest(SeeAllData=false)
public class MemoEmailControllerTest {
    @isTest static void setupData() {

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opportunityRecord;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;

        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Project__c = project.Id;
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAcc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.id);
        //bookingMemo.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        bookingMemo.ApprovalStatus__c = Constants.STATUS_APPROVED;
        insert bookingMemo;

        BookingMemo__c bookingMemo1 = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.id);        
        insert bookingMemo1;

        

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id,unit.id);
        insert memoLine;

        

        ContentDocumentLink contentDocumentLink = TestObjectsFactory.createContentDocumentLink(bookingMemo.Id);

        MemoEmailController memoEmailController = new MemoEmailController();
        
        memoEmailController.memoId = bookingMemo.Id;

        String memoProject = memoEmailController.memoProject;
        String projectBudgetId = memoEmailController.projectBudgetId;

        Integer unitCount = memoEmailController.unitCount;
        BookingMemo__c memoReqList = memoEmailController.memoReqList;

        List<MemoLines__c> memoLinesReqList = memoEmailController.memoLinesReqList;
        MemoEmailController.netImpactWrapper netImpactReq = MemoEmailController.netImpactReq;        

        List<MemoLines__c> memoTrendList = memoEmailController.memoTrendList;
        List<MemoLines__c> saleTrendList = memoEmailController.saleTrendList;
        
        List<ProjectBudget__c> budgetLineSummaryList = memoEmailController.budgetLineSummaryList;
        List<MemoEmailController.DataTableWrapper> approvalHistoryReqList = MemoEmailController.approvalHistoryReqList;

        List<String> attachmentsReqList = memoEmailController.attachmentsReqList;
        String newLine = memoEmailController.NewLine;

    }
}