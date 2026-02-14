@RestResource (urlMapping = '/query/salesorder')
global with sharing  class SalesOrderQueryWebService {

     @HttpPost
    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            
            List<SalesOrder__c> salesOrderList = SalesOrderService.getSalesOrderForManager(mapFieldApiFieldValues);
System.debug('salesOrderList '+salesOrderList);
            Boolean processRecords = false;

            SalesOrderQueryResponse response = new SalesOrderQueryResponse(salesOrderList, 'SalesOrder__c', processRecords);
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

    global with sharing class SalesOrderQueryResponse extends QueryResponse {
        
        Set<String> salesOrderStatus = new Set<String>();
        Set<String> salesOrderSubStatus = new Set<String>();
        Set<String> salesOrderProject = new Set<String>();

        global SalesOrderQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {
            super(records, objectName, processRecords);

            for (SObject record : records) {
                SalesOrder__c order = (SalesOrder__c) record;

                if (order.Status__c != null) 
                    salesOrderStatus.add(order.Status__c);
                
                if (order.SubStatus__c   != null) 
                    salesOrderSubStatus.add(order.SubStatus__c  );

                if (order.ProjectName__c   != null) 
                salesOrderProject.add(order.ProjectName__c  );
            }

        }
    }  
}