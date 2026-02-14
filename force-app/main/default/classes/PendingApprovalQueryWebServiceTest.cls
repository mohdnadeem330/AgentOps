/*
*Created By     : Hardik Vitthani
*Description    : Test class for PendingApprovalQueryWebService
*/
@isTest
public class PendingApprovalQueryWebServiceTest {
    @isTest
    public static void testPendingApprovalQueryWebService() {
        Test.startTest();

        PriceUpdateRequest__c priceUpdateRequest = TestObjectsFactory.getPriceUpdateRequestRecord();
        priceUpdateRequest.RequestedBy__c = UserInfo.getUserId();
        insert priceUpdateRequest;

        Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
        approvalProcess.setObjectId(priceUpdateRequest.Id);
        approvalProcess.setSkipEntryCriteria(true);
        // approvalProcess.setNextApproverIds(new Id[]{UserInfo.getUserId()});
        approvalProcess.setProcessDefinitionNameOrId('SellingPriceApprovalProcessv4');
        
        Approval.ProcessResult result = Approval.process(approvalProcess);

        ProcessInstanceWorkItem processInstanceItem = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        processInstanceItem.ActorId = UserInfo.getUserId();
        update processInstanceItem;
        
        String emailId = '';
        // List<ProcessInstance> pendingApprovals = [SELECT Id, CreatedById, CreatedDate, ProcessDefinitionId, ProcessDefinition.Name, Status, 
        //                                             SubmittedById, SubmittedBy.Name, SystemModstamp, TargetObjectId, (SELECT Id, 
        //                                             ProcessNodeId, StepStatus, TargetObjectId, ActorId, Actor.Email, CreatedById, IsPending, 
        //                                             OriginalActorId, ProcessInstanceId, CreatedDate FROM StepsAndWorkitems WHERE 
        //                                             IsPending = true) FROM ProcessInstance WHERE Status = 'Pending' LIMIT 1];
        // for (ProcessInstance processInstance : pendingApprovals) {
        //     System.debug('processInstance>>>' + processInstance);
        //     if (processInstance.StepsAndWorkitems.size() > 0) {
        //         emailId = processInstance.StepsAndWorkitems[0].Actor.Email;
        //         System.debug('processInstance.StepsAndWorkitems>>>' + processInstance.StepsAndWorkitems);
        //         System.debug('emailId>>>' + emailId);
        //         if (String.isNotBlank(emailId)) {
        //             break;
        //         }
        //     }
        // }
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/query/pendingapprovals';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response= res;

            PendingApprovalQueryWebService.getApprovals(UserInfo.getUserEmail());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}