@RestResource(urlMapping = '/getQuarterlyBonusReport')
global with sharing class BP_GetQuarterlyBonusReport extends BP_BaseRestResource {
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            BP_GetQuarterlyBonusReport service = new BP_GetQuarterlyBonusReport();
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
            
           
            if (!requestData.containsKey('year') || String.isEmpty((String) requestData.get('year'))) {
                return new ApiResponse(false, 400, 'Year is a mandatory parameter.', null);
            }
            
            String year = (String) requestData.get('year');
            String quarter = requestData.containsKey('quarter') ? (String) requestData.get('quarter') : null;
            Integer limitVal = requestData.containsKey('limit') ? Integer.valueOf(requestData.get('limit')) : 100;
            Integer offsetVal = requestData.containsKey('offset') ? Integer.valueOf(requestData.get('offset')) : 0;
            
            List<QuarterlyBonusCommission__c> commissionRecords = Database.query(getQuarterlyBonusCommissionQuery(year, quarter, limitVal, offsetVal));
            
            Integer totalSfCount = Database.query(getQuarterlyBonusCommissionQuery(year,quarter,null, null))?.size();

            
            Map<String, Object> responseData = new Map<String, Object>{
                'sfRecordCount' => totalSfCount, //commissionRecords.size(),
                'data' => commissionRecords
            };
            
            return new ApiResponse(true, 200, 'success', responseData);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to load data: ' + e.getMessage(), null);
        }
    }

    public static String getQuarterlyBonusCommissionQuery(String year, String quarter, Integer limitVal, Integer offsetVal) {
        String query = 'SELECT Id, Name, CurrencyIsoCode, Quarter__c, Year__c, Status__c, Approval_Status__c, BrokerAgency__c, BrokerAgency__r.Name, ' +
                       '(SELECT Id, CustomerName__c, InvoiceNumber__c, SalesOrder__c, ' +
                               'BrokerAgency__c, BrokerAgency__r.Name, ' +
                               'BrokerAgent__c, BrokerAgent__r.Name, ' +
                               'SalesOrder__r.SubStatus__c, SalesOrder__r.Status__c, ' +
                               'SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__c, ' +
                               'SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c, ' +
                               'SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c, ' +
                               'CommissionPercentage__c, CommissionType__c, InstallmentLine__c, ' +
                               'Status__c, InvoiceDate__c, PaymentDueDate__c, ClearedDate__c, ' +
                               'InstalmentNumber__c, SalesOrder__r.Opportunity__c, ' +
                               'SalesOrder__r.Opportunity__r.Contact__c, ' +
                               'SalesOrder__r.Opportunity__r.Contact__r.Name, ' +
                               'SalesOrder__r.Opportunity__r.AccountId, ' +
                               'SalesOrder__r.Opportunity__r.Account.Name, ' +
                               'CommissionAmountWithVAT__c, InstallmentLine__r.OutstandingAmount__c, ' +
                               'InstallmentLine__r.InstallmentAmount__c, InstallmentLine__r.InvoicedAmount__c ' +
                       'FROM Commission_Line_Items__r) ' +
                       'FROM QuarterlyBonusCommission__c ' +
                       'WHERE Year__c = :year ';
        
        if (quarter != null) {
            query += 'AND Quarter__c = :quarter ORDER BY LastModifiedDate DESC ';
        }
        
        if(limitVal != null){
            query += ' LIMIT :limitVal ';
        }
        
        if(offsetVal != null){
            query += ' OFFSET :offsetVal ';
        }
        
        return query;
    }
}