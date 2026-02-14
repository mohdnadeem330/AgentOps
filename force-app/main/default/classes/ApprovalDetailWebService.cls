@RestResource (urlMapping = '/query/detailapprovals')
global with sharing class ApprovalDetailWebService {

    @HttpPost
    global static void getApprovals(String contextId, String emailId) {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            RestRequest request = RestContext.request;
            handler.notMobileRequest = true;
            Map<String, List<PendingApprovalDetail>> processDetailMap = getObjectDetail(contextId, emailId);
            for (String key: processDetailMap.keySet()) {
                System.debug('processDetailMap>>>' + key + '>>>' + JSON.serialize(processDetailMap.get(key)));
                ApprovalDetailResponse response = new ApprovalDetailResponse(processDetailMap.get(key), key);

                handler.response.data = response;
                break;
            }

            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

    public static Map<String, List<PendingApprovalDetail>> getObjectDetail(String contextId, String emailId) {
        Map<String, List<PendingApprovalDetail>> returnMap = new Map<String, List<PendingApprovalDetail>>();
        
        List<PendingApprovalDetail> pendingApprovalDetailList = new List<PendingApprovalDetail>();
        //User userDetail = UserService.getUserDetailByEmail(emailId);
        User userDetail = [Select Id,Name,Email,ContactId from User where Email =: emailId and FederationIdentifier != null and isactive = True];

        List<ProcessInstance> pendingApprovals = [SELECT Id, CompletedDate, CreatedById, CreatedDate, IsDeleted, LastActorId,
                                                    LastModifiedById, LastModifiedDate, ProcessDefinitionId, ProcessDefinition.Name, Status, 
                                                    SubmittedById, SubmittedBy.Name, SystemModstamp, TargetObjectId, (SELECT Id, 
                                                    ProcessNodeId, StepStatus, Comments, TargetObjectId, ActorId, CreatedById, IsDeleted, 
                                                    IsPending, OriginalActorId, ProcessInstanceId, RemindersSent, CreatedDate 
                                                    FROM StepsAndWorkitems WHERE ActorId =: userDetail.Id AND IsPending = true 
                                                    AND Id =: contextId) FROM ProcessInstance WHERE Status = 'Pending'];
        System.debug('**pendingApprovals**' + pendingApprovals.size());

        PendingApprovalDetail pendingApprovalDetail = new PendingApprovalDetail();
        String targetObjectName = '';
        String targetObjectId = '';
        for (ProcessInstance processInstance : pendingApprovals) {
            if (processInstance.StepsAndWorkitems.size() > 0) {
                pendingApprovalDetail.targetObjectId = processInstance.TargetObjectId;
                pendingApprovalDetail.approvalProcessName = processInstance.ProcessDefinition.Name;
                pendingApprovalDetail.submittedDateTime = processInstance.CreatedDate;
                pendingApprovalDetail.contextId = processInstance.StepsAndWorkitems[0].Id;
                pendingApprovalDetail.submittedBy = processInstance.SubmittedBy.Name;
                
                targetObjectId = processInstance.TargetObjectId;
                targetObjectName = processInstance.TargetObjectId.getSObjectType().getDescribe().getName();
                break;
            }   
        }

        List<ApprovalObject> headerList = new List<ApprovalObject>();
        List<Object> detailList = new List<Object>();
        if (targetObjectName == 'SalesOrder__c') {
            List<SalesOrder__c> salesOrderDetail = [SELECT Id, Name, OwnerId, Owner.Name, AccountName__c, Unit__c, Unit__r.Name, 
                                                        SpecialConditionReason__c, SpecialConditionRemarksComments__c, ExpectedEndDate__c, 
                                                        SalesManagerName__c FROM SalesOrder__c WHERE Id =: targetObjectId LIMIT 1];
            
            for (SalesOrder__c salesOrder: salesOrderDetail) {
                headerList.add(new ApprovalObject('Customer Name', salesOrder.AccountName__c));
                headerList.add(new ApprovalObject('Unit Number', salesOrder.Unit__r.Name));
                headerList.add(new ApprovalObject('Special Condition Reason', salesOrder.SpecialConditionReason__c));
                headerList.add(new ApprovalObject('Special Condition Remarks', salesOrder.SpecialConditionRemarksComments__c));
                headerList.add(new ApprovalObject('Expected End Date', salesOrder.ExpectedEndDate__c));
                headerList.add(new ApprovalObject('Sales Manager', salesOrder.SalesManagerName__c));
                headerList.add(new ApprovalObject('Current Owner Name', salesOrder.Owner.Name));
            }
        } else if (targetObjectName == 'Opportunity') {
            List<Opportunity> opportunityDetail = [SELECT Id, Name, CustomerName__c, OpportunityNumber__c, CustomerNationality__c, 
                                                    CustomerResidentStatus__c, CustomerCity__c, ReferralType__c, EmployeeName__c, 
                                                    BrokerAgencyAccountName__c, BrokerAgentName__c, SalesAgentName__c, SaleType__c, 
                                                    DealType__c, BookingType__c, (SELECT Id, Name, UnitNumber__c, UnitProject__c, 
                                                    UnitBuilding__c, UnitTotalArea__c, SellingPrice__c, Remarks__c, NetAmount__c 
                                                    FROM OpportunityUnitsOpportunity__r) FROM Opportunity WHERE Id =: targetObjectId LIMIT 1];
            
            for (Opportunity opp: opportunityDetail) {
                headerList.add(new ApprovalObject('Customer Name', opp.CustomerName__c));
                headerList.add(new ApprovalObject('Opportunity Number', opp.OpportunityNumber__c));
                headerList.add(new ApprovalObject('Nationality', opp.CustomerNationality__c));
                headerList.add(new ApprovalObject('Residency Status', opp.CustomerResidentStatus__c));
                headerList.add(new ApprovalObject('City', opp.CustomerCity__c));
                headerList.add(new ApprovalObject('Referral Type', opp.ReferralType__c));
                headerList.add(new ApprovalObject('Employee Name', opp.EmployeeName__c));
                headerList.add(new ApprovalObject('Broker Agency Name', opp.BrokerAgencyAccountName__c));
                headerList.add(new ApprovalObject('Broker Agent Name', opp.BrokerAgentName__c));
                headerList.add(new ApprovalObject('Sales Agent Name', opp.SalesAgentName__c));
                headerList.add(new ApprovalObject('Sale Type', opp.SaleType__c));
                headerList.add(new ApprovalObject('Deal Type', opp.DealType__c));
                headerList.add(new ApprovalObject('Booking Type', opp.BookingType__c));

                for (SalesOrder__c salesOrder: opp.OpportunityUnitsOpportunity__r) {
                    List<ApprovalObject> childDetailList = new List<ApprovalObject>();
                    childDetailList.add(new ApprovalObject('Unit Number', salesOrder.UnitNumber__c));
                    childDetailList.add(new ApprovalObject('Property', salesOrder.UnitProject__c));
                    childDetailList.add(new ApprovalObject('Promotion Name', salesOrder.UnitBuilding__c));
                    childDetailList.add(new ApprovalObject('Unit Area', salesOrder.UnitTotalArea__c));
                    childDetailList.add(new ApprovalObject('Unit Selling Price', salesOrder.SellingPrice__c));
                    childDetailList.add(new ApprovalObject('Remarks', salesOrder.Remarks__c));
                    childDetailList.add(new ApprovalObject('Net Amount', salesOrder.NetAmount__c));

                    detailList.add(childDetailList);
                }
            }
        } else if (targetObjectName == 'PriceUpdateRequest__c') {
            List<PriceUpdateRequest__c> priceUpdateRequestDetail = [SELECT Id, Name, RequestorName__c, RequestDate__c, RequestorComments__c, 
                                                                        (SELECT Id, Name, RequestNumber__c, Project__c, Project__r.Name, 
                                                                        Unit__c, Unit__r.Name, Building__c, Building__r.Name, CurrentPrice__c, 
                                                                        NewPrice__c, UnitStatus__c FROM PriceUpdateUnits__r) 
                                                                        FROM PriceUpdateRequest__c WHERE Id =: targetObjectId LIMIT 1];
            
            for (PriceUpdateRequest__c priceUpdateRequest: priceUpdateRequestDetail) {
                headerList.add(new ApprovalObject('Requested By', priceUpdateRequest.RequestorName__c));
                headerList.add(new ApprovalObject('Request Date', priceUpdateRequest.RequestDate__c));
                headerList.add(new ApprovalObject('Requestor Comments', priceUpdateRequest.RequestorComments__c));

                for (PriceUpdateUnit__c priceUpdateUnit: priceUpdateRequest.PriceUpdateUnits__r) {
                    List<ApprovalObject> childDetailList = new List<ApprovalObject>();
                    childDetailList.add(new ApprovalObject('Request Number', priceUpdateUnit.RequestNumber__c));
                    childDetailList.add(new ApprovalObject('Unit', priceUpdateUnit.Project__r.Name));
                    childDetailList.add(new ApprovalObject('Project', priceUpdateUnit.Unit__r.Name));
                    childDetailList.add(new ApprovalObject('Building', priceUpdateUnit.Building__r.Name));
                    childDetailList.add(new ApprovalObject('Current Price', priceUpdateUnit.CurrentPrice__c));
                    childDetailList.add(new ApprovalObject('New Price', priceUpdateUnit.NewPrice__c));
                    childDetailList.add(new ApprovalObject('Unit Status', priceUpdateUnit.UnitStatus__c));

                    detailList.add(childDetailList);
                }
            }
        } else if (targetObjectName == 'SalesOrderCancellation__c') {
            List<SalesOrderCancellation__c> salesCancellationDetail = [SELECT Id, Name, Unit__c, Unit__r.Name, BookingDate__c, NoOfDays__c, 
                                                                        RefundApplicable__c, RefundAmount__c, RefundReason__c, 
                                                                        ReasonforCancellation__c, ContractSignedbyCustomer__c, 
                                                                        AllInstallmentProvided__c, DownPaymentStatus__c, AccountName__c, 
                                                                        Black_List_Customer__c, CancellationRequestDate__c, 
                                                                        BrokerageAgencyName__c, BrokerageAgencyName__r.Name 
                                                                        FROM SalesOrderCancellation__c WHERE Id =: targetObjectId LIMIT 1];

            for (SalesOrderCancellation__c salesCancellation: salesCancellationDetail) {
                headerList.add(new ApprovalObject('Customer Name', salesCancellation.AccountName__c));
                headerList.add(new ApprovalObject('Unit Number', salesCancellation.Unit__r.Name));
                headerList.add(new ApprovalObject('Booking Date', salesCancellation.BookingDate__c));
                headerList.add(new ApprovalObject('Cancellation Request Date', salesCancellation.CancellationRequestDate__c));
                headerList.add(new ApprovalObject('Is Refund Applicable?', salesCancellation.RefundApplicable__c));
                headerList.add(new ApprovalObject('Refund Amount', salesCancellation.RefundAmount__c));
                headerList.add(new ApprovalObject('Refund Reason', salesCancellation.RefundReason__c));
                headerList.add(new ApprovalObject('Reason for Cancellation', salesCancellation.ReasonforCancellation__c));
                headerList.add(new ApprovalObject('Down Payment Status', salesCancellation.DownPaymentStatus__c));
                headerList.add(new ApprovalObject('Is Contract Signed by Customer', salesCancellation.ContractSignedbyCustomer__c));
                headerList.add(new ApprovalObject('Is All Installment Provided', salesCancellation.AllInstallmentProvided__c));
                headerList.add(new ApprovalObject('Is Black List Customer', salesCancellation.Black_List_Customer__c));
                headerList.add(new ApprovalObject('Brokerage Agency Name', salesCancellation.BrokerageAgencyName__r.Name));
            }
        }
        pendingApprovalDetail.header = headerList;
        pendingApprovalDetail.detail = detailList;

        pendingApprovalDetailList.add(pendingApprovalDetail);
        returnMap.put(targetObjectName, pendingApprovalDetailList);
        return returnMap;
    }

    global class PendingApprovalDetail{
        public String approvalProcessName;
        public DateTime submittedDateTime;
        public String submittedBy;
        public Id contextId;
        public Id targetObjectId;
        public String approvalSubject;
        public List<ApprovalObject> header;
        public List<Object> detail;
    }

    global class ApprovalObject{
        public String key;
        public Object value;
        
        public ApprovalObject(String key, Object value) {
            this.key = key;
            this.value = value;
        }
    }

    global with sharing class ApprovalDetailResponse extends QueryResponse {
        global ApprovalDetailResponse (List<PendingApprovalDetail> records, String objectName) {
            super(records, objectName);
        }

        global ApprovalDetailResponse () {
        }
    }
}