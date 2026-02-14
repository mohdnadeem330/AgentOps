@RestResource(urlMapping = '/getSalesOrderReportInformation')
global with sharing class BP_GetSalesOrderReport extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            BP_GetSalesOrderReport service = new BP_GetSalesOrderReport();
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
            
            String accountName = (String) requestData.get('accountName');
            String accountNumber = (String) requestData.get('accountNumber');
            String agentName = (String) requestData.get('agentName');
            String agentType = (String) requestData.get('agentType');
            String projectName = (String) requestData.get('projectName');
            String unitNumber = (String) requestData.get('unitNumber');
            String unitAreaUOM = (String) requestData.get('unitAreaUOM');
            Date startDate = Date.valueOf((String) requestData.get('startDate'));
            Date endDate = Date.valueOf((String) requestData.get('endDate'));
            


           
            Integer limitValue = null;
            Integer offsetValue = null;

            if (requestData.containsKey('limit') && requestData.get('limit') != null) {
                try {
                    limitValue = Integer.valueOf((String) requestData.get('limit'));
                } catch (Exception e) {
                    return new ApiResponse(false, 400, 'Invalid limit value', null);
                }
            }

            if (requestData.containsKey('offset') && requestData.get('offset') != null) {
                try {
                    offsetValue = Integer.valueOf((String) requestData.get('offset'));
                } catch (Exception e) {
                    return new ApiResponse(false, 400, 'Invalid offset value', null);
                }
            }

            Set<String> statusValuesForReport = new Set<String>{'Pending', 'Approve Pending', 'Sold'};
            
            String query = getSalesOrderQuery(statusValuesForReport, accountName, accountNumber, agentName, agentType, 
                                              projectName, unitNumber, unitAreaUOM, startDate, endDate, limitValue, offsetValue);
            String queryWithoutLimits = getSalesOrderQuery(statusValuesForReport, accountName, accountNumber, agentName, agentType, 
                                              projectName, unitNumber, unitAreaUOM, startDate, endDate, null, null);
            
            List<SalesOrder__c> salesOrderRecords = Database.query(query);
            Integer salesOrderRecordsTotal = Database.query(queryWithoutLimits)?.size();
            
            Map<String, Object> responseData = new Map<String, Object> {
                'sfRecordCount' => salesOrderRecordsTotal,  //salesOrderRecords.size(), // count of records
                'data' => salesOrderRecords
            };
            
            return new ApiResponse(true, 200, 'success', responseData);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to load data: ' + e.getMessage(), null);
        }
    }

    public static String getSalesOrderQuery(Set<String> statusValuesForReport, String accountName, String accountNumber, 
                                            String agentName, String agentType, String projectName, String unitNumber, 
                                            String unitAreaUOM, Date startDate, Date endDate, Integer limitValue, Integer offsetValue) {
        
        String query = 'SELECT Status__c, BookingDate__c, AccountName__c, AccountNumber__c, AgentName__c, AgentType__c, ProjectName__c, ' +
                       'UnitNumber__c, UnitAreaUOM__c, UnitTotalArea__c, CreatedDate, Opportunity__c,UnitSellingPrice__c, NetAmount__c ' +
                       'FROM SalesOrder__c ' +
                       'WHERE Status__c IN :statusValuesForReport ';
        
     
       if (!String.isBlank(accountName)) {
    accountName = accountName.replaceAll('\\s+', ' ').trim();
    List<String> nameParts = accountName.split(' ');
    for (String part : nameParts) {
        if (!String.isBlank(part)) {
            query += 'AND AccountName__c LIKE \'%' + String.escapeSingleQuotes(part) + '%\' ';
        }
    }
}

  
        if (accountNumber != null && accountNumber != '') {
            query += 'AND AccountNumber__c = \'' + accountNumber + '\' ';
        }
        
        if (agentName != null && agentName != '') {
            query += 'AND AgentName__c LIKE \'%' + agentName + '%\' ';
        }
        
        if (agentType != null && agentType != '') {
            query += 'AND AgentType__c = \'' + agentType + '\' ';
        }
        
        if (projectName != null && projectName != '') {
            query += 'AND ProjectName__c LIKE \'%' + projectName + '%\' ';
        }
        
        if (unitNumber != null && unitNumber != '') {
            query += 'AND UnitNumber__c = \'' + unitNumber + '\' ';
        }
        
        if (unitAreaUOM != null && unitAreaUOM != '') {
            query += 'AND UnitAreaUOM__c = \'' + unitAreaUOM + '\' ';
        }
        
        if (startDate != null && endDate != null) {
            query += 'AND BookingDate__c >= :startDate AND BookingDate__c <= :endDate ';
        }

        query += 'ORDER BY CreatedDate DESC ';

       
        if (limitValue != null) {
            query += 'LIMIT ' + limitValue + ' ';
        }
        if (offsetValue != null) {
            query += 'OFFSET ' + offsetValue + ' ';
        }

        return query;
    }
}