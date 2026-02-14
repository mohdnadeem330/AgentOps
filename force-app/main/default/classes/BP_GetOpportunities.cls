@RestResource(urlMapping = '/GetOpportunitiesInformation')
global with sharing class BP_GetOpportunities extends BP_BaseRestResource {

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();


            BP_GetOpportunities service = new BP_GetOpportunities();
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
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String accountId = String.valueOf(requestMap.get('accountId')); 
        String contactId = String.valueOf(requestMap.get('contactId')); 
        String startDate = String.valueOf(requestMap.get('startDate'));
        String endDate = String.valueOf(requestMap.get('endDate'));
        String opportunityId = String.valueOf(requestMap.get('opportunityId'));

        Integer limitVal = params.containsKey('limit') ? Integer.valueOf(params.get('limit')) : 50;
        Integer offsetVal = params.containsKey('offset') ? Integer.valueOf(params.get('offset')) : 0;

        Map<String, Object> responseData = new Map<String, Object>();

        
        if (!String.isBlank(opportunityId)) {
            List<SalesOrder__c> salesOrders = [
                SELECT Discount__c, NetAmount__c, Status__c, UnitNumber__c, ProjectName__c, UnitType__c,  
                       UnitNumberOfRooms__c, UnitSaleableArea__c, UnitSellingPrice__c, Unit__r.TotalRooms__c 
                FROM SalesOrder__c 
                WHERE Opportunity__c = :opportunityId
            ];
            responseData.put('salesOrdersCount', salesOrders.size());
            responseData.put('salesOrders', salesOrders);
            return new ApiResponse(true, 200, 'Success', responseData);
        }

       
        String projectName = String.valueOf(requestMap.get('projectName'));
        String residentStatus = String.valueOf(requestMap.get('residentStatus'));
        String opportunityNumber = String.valueOf(requestMap.get('opportunityNumber'));
        String opportunityName = String.valueOf(requestMap.get('oppName'));
        String status = String.valueOf(requestMap.get('status'));
        String email = String.valueOf(requestMap.get('email'));
        String mobile = String.valueOf(requestMap.get('mobile'));
        String agentName = String.valueOf(requestMap.get('agentName'));
        String salesManagerName = String.valueOf(requestMap.get('salesManagerName'));

        if (String.isBlank(accountId) && String.isBlank(contactId)) {
            return new ApiResponse(false, 400, 'Either accountId or contactId must be provided.', null);
        }

        String query = getOpportunitiesQuery(accountId, contactId, startDate, endDate, projectName, residentStatus, 
                                             opportunityNumber, opportunityName, status, email, mobile, agentName, 
                                             salesManagerName, limitVal, offsetVal);

        List<Opportunity> opportunities = Database.query(query);

        responseData.put('recordCount', opportunities.size());
        responseData.put('data', opportunities);

        return new ApiResponse(true, 200, 'Success', responseData);

    } catch (Exception e) {
        return new ApiResponse(false, 400, 'Failed to fetch opportunities: ' + e.getMessage(), null);
    }
}


    public static String getOpportunitiesQuery(
        String accountId, String contactId, String startDate, String endDate, String projectName, String residentStatus, 
        String opportunityNumber, String opportunityName, String status, String email, String mobile, 
        String agentName, String salesManagerName, Integer limitVal, Integer offsetVal
    ) {
        List<String> filters = new List<String>();

       

    
        if (!String.isBlank(accountId)) {
            filters.add('BrokerAgencyAccount__r.Id = \'' + accountId + '\'');
        }
        if (!String.isBlank(contactId)) {
            filters.add('BrokerAgentContact__r.Id = \'' + contactId + '\'');
        }

      
        if (!String.isBlank(startDate) && !String.isBlank(endDate)) {
            filters.add('CreatedDate >= ' + startDate + ' AND CreatedDate <= ' + endDate);
        }
        if (!String.isBlank(projectName)) {
          
                 filters.add('Project__c = \'' + projectName + '\'');
        }
        if (!String.isBlank(residentStatus)) {
            filters.add('ResidentStatus__c = \'' + residentStatus + '\'');
        }
        if (!String.isBlank(opportunityNumber)) {
            filters.add('OpportunityNumber__c = \'' + opportunityNumber + '\'');
        }
        if (!String.isBlank(opportunityName)) {
            filters.add('Name = \'' + opportunityName + '\'');
        }
        if (!String.isBlank(status)) {
            filters.add('StageName = \'' + status + '\'');
        }
        if (!String.isBlank(email)) {
            filters.add('CustomerEmailFormula__c = \'' + email + '\'');
        }
        if (!String.isBlank(mobile)) {
            filters.add('MobileNumberFormula__c = \'' + mobile + '\'');
        }
        if (!String.isBlank(agentName)) {
            filters.add('BrokerAgentName__c = \'' + agentName + '\'');
        }
        if (!String.isBlank(salesManagerName)) {
            filters.add('SalesManager__r.Name = \'' + salesManagerName + '\'');
        }

        String query = 'SELECT Id,Account.Salutation, Account.FirstName, Account.LastName, ' +
                       'Account.PersonEmail, Account.PersonMobilePhone, StageName, BrokerAgentName__c, ' +
                       'Owner.Name, Project__c, OpportunityNumber__c, LeadNumber__c, SalesTypefromLead__c, SalesManager__r.Name,' +
                       'DealType__c, LastModifiedDate, ResidentStatus__c ' +
                       'FROM Opportunity';

     
        if (!filters.isEmpty()) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }

      
        query += ' ORDER BY LastModifiedDate DESC LIMIT ' + limitVal + ' OFFSET ' + offsetVal;

        
        return query;
    }
}