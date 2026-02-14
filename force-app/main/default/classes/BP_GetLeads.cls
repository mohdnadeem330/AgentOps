@RestResource(urlMapping = '/GetLeadsInformation')
global with sharing class BP_GetLeads extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            BP_GetLeads service = new BP_GetLeads();
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
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            String location = (String) requestData.get('location'); 
            String project = (String) requestData.get('project');
            String email = (String) requestData.get('email'); 
            String mobile = (String) requestData.get('mobile'); 
            String leadName = (String) requestData.get('leadName'); 
            String agentName = (String) requestData.get('agentName'); 
            String brokerAgentId = (String) requestData.get('brokerAgentId');

            Date startDate = requestData.containsKey('startDate') ? Date.valueOf((String) requestData.get('startDate')) : null;
            Date endDate = requestData.containsKey('endDate') ? Date.valueOf((String) requestData.get('endDate')) : null;

            String query = getLeadQuery(location, project, email, mobile, leadName, agentName, brokerAgentId, startDate, endDate);
            List<Lead> leads = Database.query(query);

            Map<String, Object> responseData = new Map<String, Object>{
                'recordCount' => leads.size(),
                'data' => leads
            };

            return new ApiResponse(true, 200, 'Success', responseData);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to fetch leads: ' + e.getMessage(), null);
        }
    }

    public static String getLeadQuery(String location, String project, String email, String mobile, String leadName, String agentName, String brokerAgentId, Date startDate, Date endDate) {
        List<String> filters = new List<String>();

        filters.add('IsConverted = false');
        filters.add('Status != \'Duplicate lead\'');
        filters.add('Status != \'Retired Lead\'');
        filters.add('Status != \'Converted Lead\'');

        if (startDate != null && endDate != null) {
            filters.add(
                '((OriginalCreationDate__c != null AND OriginalCreationDate__c >= ' + startDate + ') OR ' +
                '(OriginalCreationDate__c = null AND CreatedDate >= ' + startDate + '))'
            );
            filters.add(
                '((OriginalCreationDate__c != null AND OriginalCreationDate__c <= ' + endDate + ') OR ' +
                '(OriginalCreationDate__c = null AND CreatedDate <= ' + endDate + '))'
            );
        }

        if (location != null && location != '') {
            filters.add('Nationality__c = \'' + location + '\'');
        }
        if (project != null && project != '') {
            filters.add('Project__c = \'' + project + '\'');
        }
        if (email != null && email != '') {
            filters.add('Email = \'' + email + '\'');
        }
        if (mobile != null && mobile != '') {
            filters.add('MobilePhone = \'' + mobile + '\'');
        }
        if (leadName != null && leadName != '') {
            filters.add('Name LIKE \'%' + leadName + '%\'');
        }
        if (agentName != null && agentName != '') {
            filters.add('AgentName__c = \'' + agentName + '\'');
        }
        if (brokerAgentId != null && brokerAgentId != '') {
            filters.add('BrokerAgent__c = \'' + brokerAgentId + '\'');
        }

        String query = 'SELECT FirstName, LastName, Email, BrokerAgent__c, MobileNumber1__c, MobileNumber__c, ' +
                       'EmailAddress__c, Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, CreatedDate, ' +
                       'City, PassportNumber__c, PassportExpiryDate__c, Nationality__c, Country, Project__c, ' +
                       'UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, ' +
                       'BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, ' +
                       'LastModifiedDate, BrokerAgent__r.Name FROM Lead';

        if (!filters.isEmpty()) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }

        query += ' ORDER BY CreatedDate DESC';

        return query;
    }
}