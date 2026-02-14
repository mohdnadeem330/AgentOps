@RestResource (urlMapping = '/homepage/dashboard')
global with sharing class DashboardWebservice {
    
    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getReportData();
            handler.response.success = true;
            handler.finalize(); 
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    public static DashboardMode getReportData() {
        User userDetail = Utilities.getLoggedInUserDetail();
        
        DashboardMode finalMap = new DashboardMode();

        List<ObjectDetails> objectDetailList = new List<ObjectDetails>();
        List<TargetDetails> targetDetailList = new List<TargetDetails>();
       
        // Status
        Schema.DescribeFieldResult fieldResult = RoundRobinAssignmentMatrix__c.status__c.getDescribe();
        List<String> statusValues = new List<String>();
        for(Schema.PicklistEntry picklist: fieldResult.getPicklistValues()){
            statusValues.add(picklist.getValue());
        }
        finalMap.availabilityStatus = statusValues;

        Set<Id> userSet = new Set<Id>();
        userSet.add(userDetail.Id);
        
        Map<Id, Boolean> agentStatusMap = RoundRobinAssignmentUtility.getAgentAvailibility(userSet);
        objectDetailList.add(new ObjectDetails('Status', 'agentStatus', agentStatusMap.get(userDetail.Id) == true ? 'Available' : 'Offline'));
        // Status

        // Open Lead Count
        Decimal leadCount = 0;
        Decimal oppCloseWonCount = 0;
        Decimal leadOpenCount = 0;
        List<Lead> LeadList = LeadService.fetchLeadForAPIByUser(userDetail.Id);
        for (Lead lead: LeadList) {
            if (lead.Status == Constants.WORKING_LEAD || lead.Status == Constants.NEW_LEAD) {
                leadOpenCount += 1;
            }
            if (lead.ConvertedOpportunityId != null && lead.ConvertedOpportunity.StageName == Constants.STAGE_CLOSEDWON) {
                oppCloseWonCount += 1;
            }
            leadCount += 1;
        }
        objectDetailList.add(new ObjectDetails('Open Leads', 'openLeads', leadOpenCount));
        objectDetailList.add(new ObjectDetails('Lead to Sale (Win %)', 'leadToSale', oppCloseWonCount == 0 ? 0 : ((oppCloseWonCount / leadCount) * 100)));
        //finalMap.onlineOfflineRequests = OfflineRequestController.getOfflineRequest();
        finalMap.checkApprovedRequest = OfflineRequestController.checkApprovedRequest();
        List<OfflineRequest__c> lstOfflineReq = ( List<OfflineRequest__c>)finalMap.checkApprovedRequest.get('approvedOfflineReq');
        if(finalMap.checkApprovedRequest.get('workingHours') == true && lstOfflineReq.size() == 0 ){
            finalMap.isOnline = true;
        }
        // Open Lead Count

        // Open Opportunity Count
        List<Opportunity> OpportunityList = OpportunityService.fetchOpportunityForAPIByUser(userDetail.Id);
        Decimal oppOpenCount = 0;
        Decimal oppCloseCount = 0;
        Decimal oppCloseDays = 0;
        Decimal mortgageReferralCount = 0;
        Decimal roiCount = 0;        
        
        for (Opportunity opp: OpportunityList) {
            if (opp.StageName != Constants.STAGE_CLOSEDWON && opp.StageName != Constants.STAGE_CLOSED_LOST) {
                oppOpenCount += 1;
            } else {
                oppCloseCount += 1;
                oppCloseDays += date.newinstance(opp.CreatedDate.year(), opp.CreatedDate.month(), opp.CreatedDate.day()).daysBetween(opp.CloseDate);
            }
            if (opp.Bank__c != null) {
                mortgageReferralCount += 1;
            }
            if (opp.StageName == Constants.STAGE_MEETING || opp.StageName == Constants.STAGE_PROPOSAL) {
                roiCount += 1;
            }
        }
        objectDetailList.add(new ObjectDetails('Open Opportunities', 'openOpportunities', oppOpenCount));
        objectDetailList.add(new ObjectDetails('Mortgage Referrals', 'mortgageReferrals', mortgageReferralCount));
        objectDetailList.add(new ObjectDetails('Average Days took for Opportunity Sold', 'avgDaysOppSold', oppCloseCount == 0 ? 0 : (oppCloseDays / oppCloseCount)));
        objectDetailList.add(new ObjectDetails('ROI Meeting (%)', 'roiMeeting', roiCount == 0 ? 0 : ((roiCount / oppOpenCount) * 100)));
        // Open Opportunity Count

        // Unit Sales Order Count
        List<SalesOrder__c> salesOrderList = SalesOrderService.fetchSalesOrderForAPIByUser(userDetail.Id);
        Decimal unitPendingCount = 0;
        Decimal pendingDealAmount = 0;
        Decimal ordersSoldCount = 0;
        Decimal soldDealAmount = 0;
        Decimal totalBookedSalesOrderCount = 0;
        Decimal unitCancelledCount = 0;

        Decimal directCount = 0;
        Decimal directAmount = 0;
        Decimal indirectCount = 0;
        Decimal indirectAmount = 0;
        for (SalesOrder__c so: salesOrderList) {
            if (so.Status__c == Constants.SO_STATUS_SOLD) {
                ordersSoldCount += 1;
                soldDealAmount += (so.NetAmount__c != null ? so.NetAmount__c : 0);
            } else if (so.Status__c == Constants.OPPO_UNIT_STATUS_PENDING || so.Status__c == Constants.STATUS_APPROVAL_PENDING) {
                unitPendingCount += 1;
                pendingDealAmount += (so.NetAmount__c != null ? so.NetAmount__c : 0);
            } else if (so.Status__c == Constants.SO_STATUS_CANCELLED) {
                unitCancelledCount += 1;
            }
            if (so.Status__c == Constants.SO_STATUS_CANCELLED || so.Status__c == Constants.STATUS_APPROVAL_PENDING || so.Status__c == Constants.OPPO_UNIT_STATUS_PENDING || so.Status__c == Constants.SO_STATUS_SOLD) {
                totalBookedSalesOrderCount += 1;
            }

            if (so.Status__c == Constants.SO_STATUS_SOLD) {
                if (so.Opportunity__r.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_DIRECT) {
                    directCount += 1;
                    directAmount += (so.NetAmount__c != null ? so.NetAmount__c : 0);
                } else if (so.Opportunity__r.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT) {
                    indirectCount += 1;
                    indirectAmount += (so.NetAmount__c != null ? so.NetAmount__c : 0);
                }
            }
        }
        objectDetailList.add(new ObjectDetails('Order Pending', 'orderPending', unitPendingCount));
        objectDetailList.add(new ObjectDetails('Pending Deal Amount', 'pendingDealAmount', pendingDealAmount));
        objectDetailList.add(new ObjectDetails('Orders Sold', 'ordersSold', ordersSoldCount));
        objectDetailList.add(new ObjectDetails('Sold Deal Amount', 'soldDealAmount', soldDealAmount));
        objectDetailList.add(new ObjectDetails('Cancellation Request %', 'cancellationRequest', totalBookedSalesOrderCount == 0 ? 0 : ((unitCancelledCount / totalBookedSalesOrderCount) * 100)));

        objectDetailList.add(new ObjectDetails('Direct Sales Count', 'directSalesCount', directCount));
        objectDetailList.add(new ObjectDetails('Direct Sales Value', 'directSalesValue', directAmount));
        objectDetailList.add(new ObjectDetails('Indirect Sales Count', 'indirectSalesCount', indirectCount));
        objectDetailList.add(new ObjectDetails('Indirect Sales Value', 'indirectSalesValue', indirectAmount));
        // Unit Sales Order Count

        // Unit Commission (Earned) Sum
        AggregateResult[] CommissionEarnedSum = CommissionLineItemService.fetchCommissionLineForAPIByUser(userDetail.Id, Constants.SO_STATUS_SOLD);
        for (AggregateResult ar: CommissionEarnedSum) {
            objectDetailList.add(new ObjectDetails('Commission Earned (AED)', 'commissionEarned', (ar.get('expr0') != null ? (Decimal)ar.get('expr0') : 0)));
        }
        // Unit Commission (Earned) Sum

        // Open Meeting
        Decimal closedTaskCount = 0;
        Decimal customerResponse = 0;
        Decimal customerResponseCount = 0;
        List<Task> taskList = TaskService.fetchTaskForAPIByUser(userDetail.Id);
        system.debug('taskList::'+taskList);
        for (Task tk: taskList) {
            if (tk.CustomerResponse__c == Constants.CUSTOMER_REACHED) {
                if (tk.ReminderDateTime != null) {
                    customerResponseCount += 1;

                    Long seconds = (tk.ReminderDateTime.getTime() - tk.LastModifiedDate.getTime()) / 1000;
                    if (tk.Subject == Constants.TASK_TYPE_DAY1) {
                        Decimal hour = Decimal.valueOf(Label.Task1);
                        customerResponse += (hour - (seconds / 3600));
                    } else if (tk.Subject == Constants.TASK_DAY1) {
                        Decimal hour = Decimal.valueOf(Label.ROUNDROBIN_SM_SLA);
                        customerResponse += (hour - (seconds / 3600));
                    }
                }
            } else if (tk.CustomerResponse__c == null) {
                closedTaskCount += 1;
            }
        }
        objectDetailList.add(new ObjectDetails('Customer Response (hrs)', 'customerResponse', customerResponseCount == 0 ? 0 : (customerResponse / customerResponseCount)));
        objectDetailList.add(new ObjectDetails('# of Breached SLAs', 'noMeetingPlanned', closedTaskCount));
        // Open Meeting

        // Target
        AggregateResult[] TargetAchievedSum = MonthlySalesTargetService.fetchMonthlySalesTargetForAPIByUser(userDetail.Id);
        for (AggregateResult ar: TargetAchievedSum) {
            targetDetailList.add(new TargetDetails('Launch Target', 'launchTarget', ar.get('launchTarget') == null ? 0 : ar.get('launchTarget'), ar.get('launchAchieved') == null ? 0 : ar.get('launchAchieved')));
            targetDetailList.add(new TargetDetails('Inventory Target', 'inventoryTarget', ar.get('inventoryTarget') == null ? 0 : ar.get('inventoryTarget'), ar.get('inventoryAchieved') == null ? 0 : ar.get('inventoryAchieved')));
        }
        // Target

        // Agent Rank
        String currentYear = String.valueOf(Date.today().year());
        AggregateResult[] achievedSumList = MonthlySalesTargetService.fetchMonthlySalesTargetRank();
        List<Decimal> achievedList = new List<Decimal>();
        Map<Decimal, String> achievedMap = new Map<Decimal, String>();
        Boolean isResource = false;
        for (AggregateResult ar: achievedSumList) {
            Decimal achievedAmount = ar.get('achieved') == null ? 0 : (Decimal)ar.get('achieved');
            if (achievedMap.containsKey(achievedAmount)) {
                String resources = achievedMap.get(achievedAmount) + ',' + (String)ar.get('ResourceName__c');
                achievedMap.put(achievedAmount, resources);
            } else {
                achievedMap.put(achievedAmount, (String)ar.get('ResourceName__c'));
            }
            achievedList.add(achievedAmount);
            if(!isResource && (String)ar.get('ResourceName__c') == userDetail.Id) {
                isResource = true;
            }
        }
        achievedList.sort();
        
        Decimal rank = 0;
        if(isResource) {
            List<Decimal> finalList = new List<Decimal>();
            for(Integer i = achievedList.size()-1; i>=0; i--){
                finalList.add(achievedList.get(i));
            }
            System.debug('finalList>>>' + finalList);
            System.debug('achievedMap>>>' + achievedMap);
            for (Decimal amount: finalList) {
                rank ++;
                System.debug('rank>>>' + rank);
                if (achievedMap.get(amount).contains(userDetail.Id)) {
                    System.debug('true');
                    break;
                }
            }
        }
        
        objectDetailList.add(new ObjectDetails('Rank', 'rank', rank));
        // Agent Rank

        finalMap.dashboardComponents = objectDetailList;
        finalMap.targetDetails = targetDetailList;

        System.debug('finalMap>>>' + JSON.serialize(finalMap));
        return finalMap;
    }

    global class DashboardMode {
        public List<String> availabilityStatus                    {get;set;}
        public List<ObjectDetails> dashboardComponents            {get;set;}
        public List<TargetDetails> targetDetails                  {get;set;}
       // public List<object>  onlineOfflineRequests                {get;set;}   
        public boolean isOnline = false;  
        public Map<String, Object> checkApprovedRequest           {get; set;}
    }

   
    global class ObjectDetails {
        public String label {get;set;}
        public String key   {get;set;}
        public Object value {get;set;}
        
        public ObjectDetails(String label, String key, Object value) {
            this.label = label;
            this.key = key;
            this.value = value;
        }
    }

    global class TargetDetails {
        public String label    {get;set;}
        public String key      {get;set;}
        public Object target   {get;set;}
        public Object achieved {get;set;}

        public TargetDetails(String label, String key, Object target, Object achieved) {
            this.label = label;
            this.key = key;
            this.target = target;
            this.achieved = achieved;
        }
    }
}