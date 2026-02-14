/*
*Created By     : Hardik Vitthani
*Description    : Test class for ApprovalDetailWebService
*/
@isTest
public class ApprovalDetailWebServiceTest {
    @isTest
    public static void testApprovalDetailWebServiceSalesOrder() {
        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('2364');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.OwnerManger__c =UserInfo.getUserId();
        insert salesOrder;

        Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
        approvalProcess.setObjectId(salesOrder.Id);
        approvalProcess.setSkipEntryCriteria(true);
        approvalProcess.setProcessDefinitionNameOrId('SpecialConditionApproval');
        
        Approval.ProcessResult result = Approval.process(approvalProcess);

        ProcessInstanceWorkItem processInstanceItem = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        processInstanceItem.ActorId = UserInfo.getUserId();
        update processInstanceItem;
        
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/query/detailapprovals';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response= res;

            ApprovalDetailWebService.getApprovals(processInstanceItem.Id, UserInfo.getUserEmail());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testApprovalDetailWebServicePriceUpdateRequest() {
        Test.startTest();

        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        insert unit;

        PriceUpdateRequest__c priceUpdateRequest = TestObjectsFactory.getPriceUpdateRequestRecord();
        insert priceUpdateRequest;

        PriceUpdateUnit__c priceUpdateUnit = TestObjectsFactory.getPriceUpdateUnitRecord(priceUpdateRequest.Id, project.Id, buildingSection.Id, unit.Id);
        insert priceUpdateUnit;

        Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
        approvalProcess.setObjectId(priceUpdateRequest.Id);
        approvalProcess.setSkipEntryCriteria(true);
        approvalProcess.setProcessDefinitionNameOrId('SellingPriceApprovalProcessv4');
        
        Approval.ProcessResult result = Approval.process(approvalProcess);

        ProcessInstanceWorkItem processInstanceItem = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        processInstanceItem.ActorId = UserInfo.getUserId();
        update processInstanceItem;
        
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/query/detailapprovals';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response= res;

            ApprovalDetailWebService.getApprovals(processInstanceItem.Id, UserInfo.getUserEmail());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testApprovalDetailWebServiceOpportunity() {
        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('2364');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        insert salesOrder;

        Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
        approvalProcess.setObjectId(opp.Id);
        approvalProcess.setSkipEntryCriteria(true);
        approvalProcess.setProcessDefinitionNameOrId('Reservation_Approval');
        
        Approval.ProcessResult result = Approval.process(approvalProcess);

        ProcessInstanceWorkItem processInstanceItem = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        processInstanceItem.ActorId = UserInfo.getUserId();
        update processInstanceItem;
        
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/query/detailapprovals';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response= res;

            ApprovalDetailWebService.getApprovals(processInstanceItem.Id, UserInfo.getUserEmail());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testApprovalDetailWebServiceSalesCancellation() {
        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('23459');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        insert salesOrder;

        SalesOrderCancellation__c salesCancellation = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder.Id, unit.Id);
        salesCancellation.LineManager__c = UserInfo.getUserId();
        insert salesCancellation;

        Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
        approvalProcess.setObjectId(salesCancellation.Id);
        approvalProcess.setSkipEntryCriteria(true);
        approvalProcess.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        approvalProcess.setProcessDefinitionNameOrId('Sales_Cancellation_ApprovalV17');
        
        Approval.ProcessResult result = Approval.process(approvalProcess);

        // List<Id> newWorkItemIds = result.getNewWorkitemIds();

        // Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        // req2.setComments('Approving request.');
        // req2.setAction('Approve');
        // req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        // req2.setWorkitemId(newWorkItemIds.get(0));
        
        // Approval.ProcessResult result2 = Approval.process(req2);

        ProcessInstanceWorkItem processInstanceItem = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        // processInstanceItem.ActorId = UserInfo.getUserId();
        update processInstanceItem;
        
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/query/detailapprovals';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response= res;

            ApprovalDetailWebService.getApprovals(processInstanceItem.Id, UserInfo.getUserEmail());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}