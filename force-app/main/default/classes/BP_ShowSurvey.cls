@RestResource(urlMapping='/getSurveyDetails')
global without sharing class BP_ShowSurvey extends BP_BaseRestResource {

    @HttpPost
    global static void start(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);
            
            if(!String.isEmpty(requestBody)){   
                BP_ShowSurvey service = new BP_ShowSurvey();
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){ handler.response.success = false; handler.response.statusCode = 500; handler.response.message = ex.getMessage(); } 
        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            AccountResponse wrap = (AccountResponse) System.JSON.deserialize(requestBody, AccountResponse.class);

            if(String.isBlank(wrap.accountId)){
                return new ApiResponse(false, 400,'Account Id should not be blank', null);

            }

            return new ApiResponse(true, 200,'Survey data has been fetched Successfully', getAccountDetails(wrap.accountId));
            
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Survey data fetched failed: ' + e.getMessage(), null);
        }
    }

    static AccountWrapper getAccountDetails(String accountId) {
        List<Account> accounts = [SELECT Id, Name, ParentId,BrokerClassification__r.Name,BadgesTier__c,
                                  BrokerOverallCSAT__c FROM Account WHERE Id = :accountId LIMIT 1];
    
        AccountWrapper response = new AccountWrapper();
       
        for (Account acc : accounts) {
            AccountWrapper wrap = new AccountWrapper();
            response.id = acc.Id;
            response.name = acc.Name;
            response.parentId = acc.ParentId;
            response.brokerClassificationName =
                acc.BrokerClassification__r != null
                ? acc.BrokerClassification__r.Name
                : null;
            response.badgesTier = acc.BadgesTier__c;
            response.csatScore = acc.BrokerOverallCSAT__c;
            response.category = acc.BrokerClassification__r != null ? acc.BrokerClassification__r.Name : null;
        }
        return response;
    }

    global class AccountResponse {
        public String accountId;
    }

    global class AccountWrapper {
        public Id id;
        public String name;
        public Id parentId;
        public String brokerClassificationName;
        public String badgesTier;
        public Decimal csatScore;
        public String category;
    }
}