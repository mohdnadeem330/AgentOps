@RestResource(urlMapping = '/GetLeadsOppsSalesOrders')
global with sharing class BP_GetLeadOppSalesorders extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
       
            
            BP_GetLeadOppSalesorders service = new BP_GetLeadOppSalesorders();
            ApiResponse response = service.processRequest(params, requestBody);
            
            handler.response.data = response.data;
            handler.response.success = response.success;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        } catch (Exception ex) {
    
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        }
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
String userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
            if (currentUser.ContactId == null) {
                return new ApiResponse(false, 400, 'User does not have an associated Contact.', null);
            }
            
            Contact currentUserContact = [SELECT Id, AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
            
            if (currentUserContact.AccountId == null) {
                return new ApiResponse(false, 400, 'Contact does not have an associated Account.', null);
            }
            
            String accountId = currentUserContact.AccountId;
            String contactId = currentUser.ContactId;
            
            String startDate = params.containsKey('startDate') ? params.get('startDate') : '2024-01-20T15:00:01';
            
            List<Opportunity> opportunities = fetchOpportunities(contactId, accountId, startDate);
            List<SalesOrder__c> salesOrders = fetchSalesOrders(contactId, accountId, startDate);
            List<Lead> leads = fetchLeads(contactId, accountId, startDate);
                        
            Map<String, Object> responseData = new Map<String, Object>{
                'leads' => new Map<String, Object>{
                    'leads count' => leads.size(),
                        'data' => leads
                        },
                            'opportunities' => new Map<String, Object>{
                                'opportunities count' => opportunities.size(),
                                    'data' => opportunities
                                    },
                                        'salesOrders' => new Map<String, Object>{
                                            'salesOrders count' => salesOrders.size(),
                                                'data' => salesOrders
                                                }
            };
                
                return new ApiResponse(true, 200, 'Success', responseData);
        }catch (Exception e) {
           
            return new ApiResponse(false, 400, 'Failed to fetch data: ' + e.getMessage(), null);
        }
    }
    
    private List<Lead> fetchLeads(String contactId, String accountId, String startDate) {
        
        
        String query = 'SELECT Id, FirstName, LastName, Email, BrokerAgent__c, MobileNumber1__c, ' +
            'MobileNumber__c, EmailAddress__c, Salutation, NationalId__c, ' +
            'BrokerAgency__r.AgencyRegion__c, CreatedDate, City, PassportNumber__c, ' +
            'PassportExpiryDate__c, Nationality__c, Country, Project__c, UnitType__c, ' +
            'Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, ' +
            'BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, ' +
            'LastModifiedDate, BrokerAgent__r.Name ' +
            'FROM Lead WHERE isConverted = false ' +
            'AND Status NOT IN (\'Duplicate Lead\', \'Retired Lead\', \'Converted Lead\') ';
        
        
        if (accountId != null) {
            query += 'AND BrokerAgency__c = :accountId '; 
            
        } else {
            query += 'AND BrokerAgent__c = :contactId ';
        }
        
        query += 'WITH SECURITY_ENFORCED';
        
       
        
        return Database.query(query);
    }
    
    
    
    private List<Opportunity> fetchOpportunities(String contactId, String accountId, String startDate) {
        
        
        
        
        String query = 'SELECT Account.Salutation, Account.FirstName, Account.LastName, ' +
            'Account.PersonEmail, Account.PersonMobilePhone, StageName, ' +
            'BrokerAgentName__c, Owner.Name, Project__c, OpportunityNumber__c, ' +
            'LeadNumber__c, SalesTypefromLead__c, DealType__c, LastModifiedDate, ' +
            'ResidentStatus__c ' +
            'FROM Opportunity WHERE isClosed = false ';
        
        
        if (accountId != null) {
            query += 'AND BrokerAgencyAccount__c =:accountId ';
                
        } else {
            query += 'AND BrokerAgentContact__c = :contactId ';
        }
        
      
        
        
        return Database.query(query);
    }
    
    
    private List<SalesOrder__c> fetchSalesOrders(String contactId, String accountId, String startDate) {
        
        
        String query = 'SELECT Id, NetAmount__c, ExternalCommissionAmount__c, Status__c, ProjectName__c, ' +
            'BookingDate__c FROM SalesOrder__c WHERE Status__c IN (\'Sold\', \'Approve Pending\', \'Pending\') ';
        
        if (accountId != null) {
            query += 'AND Opportunity__r.BrokerAgencyAccount__c =:accountId ';
            
            
            
        } else {
            query += 'AND Opportunity__r.BrokerAgentContact__c = :contactId ';
        }
        
        query += 'WITH SECURITY_ENFORCED';
        
        
        
        
        List<SalesOrder__c> salesOrders = Database.query(query);
        
        
        Decimal totalCommissionEarned = 0;
        Decimal totalSalesValue = 0;
        
        for (SalesOrder__c order : salesOrders) {
            if (order.ExternalCommissionAmount__c != null) {
                totalCommissionEarned += order.ExternalCommissionAmount__c;
            }
            if (order.NetAmount__c != null) {
                totalSalesValue += order.NetAmount__c;
            }
        }
        
       
        
        return salesOrders;
    }
    
    
}