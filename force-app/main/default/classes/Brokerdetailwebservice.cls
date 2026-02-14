@RestResource(urlMapping='/LiveAldar/BrokerDetailList')
global with sharing class Brokerdetailwebservice {
    
    // Utility class for standard response
    global class StandardResponse {
        public Boolean success;
        public Integer statusCode; 
        public String requestId;
        public String message;
        public Object data;
        
        public StandardResponse(Boolean success, Integer statusCode, String message, Object data) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
            
        }
    }
    
    // Wrapper for brokerDetails response
    global class BrokerDetailsWrapper {
        public Map<String, AccountInfo> brokerDetails;
        
        public BrokerDetailsWrapper() {
            brokerDetails = new Map<String, AccountInfo>();
        }
    }
    
    // Account Info wrapper
    global class AccountInfo {
        public String Name;
        public String Email;
        public String Phone;
        
        public AccountInfo(Account acc) {
            this.Name = acc.Name;
            this.Email = acc.Email__c;
            this.Phone = acc.Phone;
        }
    }
    
    // GET method - return 50 accounts
    @HttpGet
    global static void getAccounts() {
        RestRequest req = RestContext.request;
        String brokerName = req.params.get('BrokerName');
        system.debug('BrokerName@@@'+brokerName);
        List<Account> accounts;
        if(brokerName !=null){
            accounts = [
            SELECT Id, Name, Phone, Email__c
            FROM Account
           WHERE Name LIKE :('' + brokerName + '%') AND AgencyStatus__c = 'Active' AND RecordType.DeveloperName = 'Broker_Agency' 
            LIMIT 50
        ];
        }
        else{
            accounts = [
            SELECT Id, Name, Phone, Email__c
            FROM Account WHERE AgencyStatus__c = 'Active' AND RecordType.DeveloperName = 'Broker_Agency'
            LIMIT 50
        ];
        }
        
        
        BrokerDetailsWrapper wrapper = new BrokerDetailsWrapper();
        
        for (Account acc : accounts) {
            wrapper.brokerDetails.put(acc.Id, new AccountInfo(acc));
        }
        
        StandardResponse response = new StandardResponse(true, 200, 'Success', wrapper);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
 
   
}