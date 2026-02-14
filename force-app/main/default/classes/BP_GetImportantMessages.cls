@RestResource(urlMapping = '/getImportantMessagesInformation')
global with sharing class BP_GetImportantMessages extends BP_BaseRestResource {

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            BP_GetImportantMessages service = new BP_GetImportantMessages();
            ApiResponse response = service.processRequest(params, requestBody);
            handler.response.data = response.data;
            handler.response.success = true;
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
        
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String userId = (String) requestBodyMap.get('userId');
        
        List<String> conditions = new List<String>();
        String commQuery = getCommunicationQuery();
        List<Communication__c> commList = new List<Communication__c>();
        
        
        conditions.add('Recipient__c = :userId');
        conditions.add('isPublished__c = true');
        conditions.add('CreatedDate = LAST_N_DAYS:60');
       
        if (!conditions.isEmpty()) {
            commQuery += ' ' + String.join(conditions, ' AND ');
        }

        commQuery += ' WITH SECURITY_ENFORCED ORDER BY lastModifiedDate DESC';

      
        commList = Database.query(commQuery);


        return new ApiResponse(true, 200, 
            commList.size() > 0 ? 
                'Communication details fetched. Total - ' + commList.size() :
                'No Communication data to fetch', 
            commList);
    } catch (Exception e) {
        LoggerService.save(LoggerService.addApexLog(e,'Broker2.0 API','BP_GetImportantMessages','getCommunicationQuery'));
        return new ApiResponse(false, 400, 'Failed to load Communication details: ' + e.getMessage(), null);
    }
}


    public static String getCommunicationQuery() {
        String commQuery = 'SELECT id, CommunicationTemplate__r.Title__c, CommunicationTemplate__r.PlainTextBody__c, lastModifiedDate FROM Communication__c WHERE ';
        return commQuery;
    }
}