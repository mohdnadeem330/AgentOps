@RestResource (urlMapping = '/query/account')
global with sharing class AccountQueryWebService {
    
    @HttpPost

    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mpFldApiFldValues = handler.getRequestBodyMap();
            Utilities.objType = 'Account';
         
            System.debug('mpFldApiFldValues '+mpFldApiFldValues);

            if (mpFldApiFldValues != null && mpFldApiFldValues.keySet().contains('Id')) {
                AccountDetailModel accountDetailModel = new AccountDetailModel();
                List<CountDetails> countDetailList = new List<CountDetails>();
                String accountId = mpFldApiFldValues.get('Id');
                System.debug('accountId '+accountId);
                List<Account> accountList = AccountService.fetchAccountById(accountId);
                Account queriedAcc = accountList[0];
                
                List<Lead> leadList = LeadService.fetchLeadByAccountId(accountId);
                List<Opportunity> opportunityList = OpportunityService.fetchOpportunitiesByAccountId(accountId);
                List<Task> activityList = TaskService.fetchTasksByAccountId(accountId);                
                List<SalesOrder__c> salesOrderList = SalesOrderService.fetchSalesOrderByAccountId(accountId);
                
                Decimal openLeads = 0;
                Decimal openOpportunities = 0;
                Decimal openActivities = 0;
                Decimal openOrders = 0;
                
                for(Lead lead : leadList){
                    if (lead.Status == Constants.WORKING_LEAD || lead.Status == Constants.NEW_LEAD)
                        openLeads += 1;
                }
                
                for(Opportunity opp : opportunityList){
                    if (opp.StageName != Constants.STAGE_CLOSEDWON && opp.StageName != Constants.STAGE_CLOSED_LOST)
                        openOpportunities += 1;
                }
                
                for(Task tk : activityList){
                    if (tk.Status == Constants.TASK_OPEN)
                        openActivities += 1;
                }
                
                for(SalesOrder__c order : salesOrderList){
                    if (order.Status__c == 'Pending')
                        openOrders += 1;
                }
                countDetailList.add(new CountDetails('Open leads', openLeads,'openLeads'));
                countDetailList.add(new CountDetails('Total leads', leadList.size(),'totalLeads'));
                countDetailList.add(new CountDetails('Open Opportunities', openOpportunities,'openOpportunities'));
                countDetailList.add(new CountDetails('Total Opportunities', opportunityList.size(),'totalOpportunities'));
                countDetailList.add(new CountDetails('Open Activities', openActivities,'openActivities'));
                countDetailList.add(new CountDetails('Total Activities', activityList.size(),'totalActivities'));
                countDetailList.add(new CountDetails('Open Orders', openOrders,'openOrders'));
                countDetailList.add(new CountDetails('Total Orders', salesOrderList.size(),'totalOrders'));
                
                accountDetailModel.countDetails = countDetailList;
                accountDetailModel.accountRecord = queriedAcc;

                Map<Id,Document__c> documentDetailMap = new Map<Id,Document__c> (queriedAcc.Documents__r);
                Map<Id,DocumentQueryModel> documentData = new Map<Id,DocumentQueryModel>();

                if(documentDetailMap != null && !documentDetailMap.isEmpty())
                    documentData =  DocumentService.getDocumentDetails(documentDetailMap);
                    
                accountDetailModel.documents = documentData.values();  
                
                handler.response.data = accountDetailModel;
            }
            else {
                List<Account> accounts = AccountService.getAllAccounts(mpFldApiFldValues);
                AccountQueryResponse response = new AccountQueryResponse(accounts, 'Account', false);
                handler.response.data = response;
            }

            

            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            System.debug('msg  '+exc.getMessage());
            System.debug('line  '+exc.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }
    
    global with sharing class AccountQueryResponse extends QueryResponse {
        
        global AccountQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {   
            super(records, objectName, processRecords);

            for (SObject record : records) {
                Account account = (Account) record;
                if (account.Email__c == null && account.PersonEmail !=null) 
                    account.Email__c = account.PersonEmail;
                
                if (account.MobileNumber__c == null && account.MobilePhone__pc !=null) 
                    account.MobileNumber__c = account.MobilePhone__pc;
            }
        }
    }
    
    
    public class AccountDetailModel{
        public Account accountRecord                {get;set;}   
        public List<CountDetails> countDetails      {get;set;}
        public List<DocumentQueryModel> documents   {get;set;}   
        
        public AccountDetailModel(){
            this.accountRecord = new Account();
            this.countDetails = new List<countDetails>();
            this.documents = new List<DocumentQueryModel>();
        }
    }

    public class CountDetails{
        public String label {get;set;}   
        public Object value {get;set;}
        public String key   {get;set;}   
        public CountDetails(String label, Object value, String key) {
            this.label = label;
            this.value = value;
            this.key = key;
        }
    }
}